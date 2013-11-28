#include <config.h>

#include <stdbool.h>
#include <stdint.h>
#include <stdarg.h>
#include <string.h>

#include <glib.h>
#include <hiredis/hiredis.h>
#include <hiredis/async.h>

#include "glib-hiredis.h"

#include "vrt.h"
#include "bin/varnishd/cache.h"

#include "vcc_if.h"

#ifndef NDEBUG
#define dbgprintf(sp, ...) VSL(SLT_VCL_trace, ((sp) == NULL ? 0 : ((struct sess *) (sp))->id), __VA_ARGS__)
#else
#define dbgprintf(...) ((void) 0)
#endif

GRecMutex hiredis_lock;

typedef struct {
	uint64_t magic;
#define REDIS_MAGIC 0x0be7c29131fbd7a4ULL
	redisAsyncContext *redis;
	gint errored;
	GThread *io_thread;
	GMainContext *io_context;
	GMainLoop *io_loop;
} RedisState;

typedef struct {
	GMainContext *io_context;
	GMainLoop *io_loop;
} RedisIoThreadState;

static void free_redis_state( RedisState *rs ) {
	if( rs->redis != NULL ) {
		g_rec_mutex_lock(&hiredis_lock);
		redisAsyncDisconnect(rs->redis);
		g_rec_mutex_unlock(&hiredis_lock);
	}
	g_main_loop_quit(rs->io_loop);
	g_thread_join(rs->io_thread);
	g_thread_unref(rs->io_thread);
	g_main_loop_unref(rs->io_loop);
	g_main_context_unref(rs->io_context);
	g_slice_free(RedisState, rs);
}

static void io_thread_main( RedisIoThreadState *ts ) {
	dbgprintf(0, "io_thread_main: begin");
	g_main_context_push_thread_default(ts->io_context);
	g_main_loop_run(ts->io_loop);
	g_slice_free(RedisIoThreadState, ts);
	dbgprintf(0, "io_thread_main: end");
}

static void init_redis_state( RedisState *rs ) {
	rs->magic = REDIS_MAGIC;
	rs->redis = NULL;
	rs->errored = false;
	rs->io_context = g_main_context_new();
	rs->io_loop = g_main_loop_new(rs->io_context, false);

	RedisIoThreadState *ts = g_slice_new(RedisIoThreadState);
	ts->io_context = rs->io_context,
	ts->io_loop = rs->io_loop;
	rs->io_thread = g_thread_new("vmod-redis-io", (GThreadFunc) io_thread_main, ts);
}

static RedisState *new_redis_state() {
	RedisState *rs = g_slice_new(RedisState);
	init_redis_state(rs);
	return rs;
}

// -- hiredis util functions

typedef struct {
	void (*func)( redisAsyncContext *, redisReply *, void * );
	void *data;
} RedisResponseClosure;

typedef struct {
	RedisState *rs;
	struct {
		GMutex lock;
		GCond cond;
		bool value;
	} done;
	RedisResponseClosure *closure;
} RedisResponseState;

void redis_response_callback( redisAsyncContext *c, redisReply *reply, RedisResponseState *rrs ) {
	(void) c;

	if( reply->type == REDIS_REPLY_ERROR ) {
		VSL(SLT_VCL_error, 0, "redis_response_callback: error '%s'", reply->str);
		g_atomic_int_set(&rrs->rs->errored, 1);
	} else if( rrs->closure != NULL ) {
		g_assert(rrs->closure->func != NULL);
		rrs->closure->func(c, reply, rrs->closure->data);
	}

	g_mutex_lock(&rrs->done.lock);
	rrs->done.value = true;
	g_cond_broadcast(&rrs->done.cond);
	g_mutex_unlock(&rrs->done.lock);
}

void redis_connect_callback( const redisAsyncContext *c ) {
	(void) c;

	if( c->err == REDIS_ERR ) {
		VSL(SLT_VCL_error, 0, "redis_disconnect_callack: error '%s'", c->errstr);
	} else {
		dbgprintf(0, "redis_connect_callback: Connected!");
	}
}

typedef struct {
	GMutex lock;
	GCond cond;
	bool disconnected;
} RedisDisconnectArgs;

void redis_disconnect_callback( const redisAsyncContext *c, int status ) {
	(void) status;

	if( status == REDIS_ERR || c->err == REDIS_ERR ) {
		VSL(SLT_VCL_error, 0, "redis_disconnect_callack: error '%s'", c->errstr);
	} else {
		dbgprintf(0, "redis_disconnect_callback: Disconnected");
	}

	RedisState *rs = g_dataset_get_data(c, "redis-state");
	g_dataset_remove_data(c, "redis-state");

	g_rec_mutex_lock(&hiredis_lock);
	redisGlibDetach(rs->redis);
	g_rec_mutex_unlock(&hiredis_lock);

	rs->redis = NULL;

	RedisDisconnectArgs *args = g_dataset_get_data(c, "redis-disconnect-args");
	g_assert(args != NULL);
	g_dataset_remove_data(c, "redis-disconnect-args");

	g_mutex_lock(&args->lock);
	args->disconnected = true;
	g_cond_broadcast(&args->cond);
	g_mutex_unlock(&args->lock);
}

void redis_command( RedisState *rs, RedisResponseClosure *closure, const char *cmd, va_list ap ) {
	if( cmd == NULL ) return;

	if( rs->redis == NULL ) return;

	RedisResponseState rrs = {
		.rs = rs,
		.done = {
			.value = false
		},
		.closure = closure
	};

	g_mutex_init(&rrs.done.lock);
	g_cond_init(&rrs.done.cond);

	g_mutex_lock(&rrs.done.lock);

	g_rec_mutex_lock(&hiredis_lock);
	redisvAsyncCommand(rs->redis, (redisCallbackFn *) redis_response_callback, &rrs, cmd, ap);
	g_rec_mutex_unlock(&hiredis_lock);

	while( !rrs.done.value ) {
		dbgprintf(0, "redis_command: waiting...");
		g_cond_wait(&rrs.done.cond, &rrs.done.lock);
		dbgprintf(0, "redis_command: done");
	}

	g_mutex_unlock(&rrs.done.lock);

	g_cond_clear(&rrs.done.cond);
	g_mutex_clear(&rrs.done.lock);
}

// -- util functions

static bool contains_null_strings( const char *cmd, va_list ap ) {
	if( cmd == NULL ) return true;

	const char *s = NULL;
	do {
		s = va_arg(ap, const char *);
		if( s == NULL ) {
			VSL(SLT_VCL_error, 0, "contains_null_strings: Found NULL string arguments");
			return true;
		}
	} while( s != vrt_magic_string_end );

	return false;
}

// -- vmod functions

static void vmod_redis_free( RedisState *rs ) {
	free_redis_state(rs);
}

int vmod_redis_init( struct vmod_priv *global, const struct VCL_conf *conf ) {
	(void) conf;
	dbgprintf(0, "vmod_redis_init");

	global->priv = new_redis_state();
	global->free = (vmod_priv_free_f *) vmod_redis_free;
	return 0;
}

static RedisState *redis_state( struct vmod_priv *global ) {
	g_assert(global->priv != NULL);
	RedisState *ret = (RedisState *) global->priv;
	g_assert(ret->magic == REDIS_MAGIC);
	return ret;
}

void vmod_disconnect( struct sess *sp, struct vmod_priv *global ) {
	(void) sp;
	dbgprintf(sp, "vmod_disconnect");

	RedisDisconnectArgs args = {
		.disconnected = false
	};
	g_mutex_init(&args.lock);
	g_cond_init(&args.cond);

	RedisState *rs = redis_state(global);

	g_dataset_set_data(rs->redis, "redis-disconnect-args", &args);

	g_rec_mutex_lock(&hiredis_lock);
	redisAsyncDisconnect(rs->redis);
	g_rec_mutex_unlock(&hiredis_lock);

	g_mutex_lock(&args.lock);
	while( !args.disconnected )
		g_cond_wait(&args.cond, &args.lock);
	g_mutex_unlock(&args.lock);

	g_mutex_clear(&args.lock);
	g_cond_clear(&args.cond);
}

void vmod_command_void( struct sess *sp, struct vmod_priv *global, const char *cmd, ... ) {
	g_return_if_fail(cmd != NULL);
	dbgprintf(sp, "vmod_command_void: cmd = '%s'", cmd);

	RedisState *rs = redis_state(global);

	if( g_atomic_int_get(&rs->errored) ) {
		VSL(SLT_VCL_error, sp->id, "vmod_command_void: Skipping due to recorded error condition");
		return;
	}

	va_list ap, ap2;
	va_start(ap, cmd);
	va_copy(ap2, ap);

	if( !contains_null_strings(cmd, ap) )
		redis_command(rs, NULL, cmd, ap2);

	va_end(ap);
	va_end(ap2);
	return;
}

void vmod_connect( struct sess *sp, struct vmod_priv *global, const char *host, int port ) {
	g_return_if_fail(host != NULL);

	dbgprintf(sp, "vmod_connect: host = '%s', port = %d", host, port);

	RedisState *rs = redis_state(global);

	g_assert(rs->redis == NULL && "vmod_connect called multiple times!");

	g_rec_mutex_lock(&hiredis_lock);
	rs->redis = redisAsyncConnect(host, port);
	redisAsyncSetConnectCallback(rs->redis, (redisConnectCallback *) redis_connect_callback);
	redisAsyncSetDisconnectCallback(rs->redis, redis_disconnect_callback);
	g_rec_mutex_unlock(&hiredis_lock);

	g_dataset_set_data(rs->redis, "redis-state", rs);

	g_rec_mutex_lock(&hiredis_lock);
	redisGlibAttach(rs->io_context, rs->redis);
	g_rec_mutex_unlock(&hiredis_lock);

	// This should serve to block us until the connection is complete.
	vmod_command_void(sp, global, "PING", vrt_magic_string_end);
}

static void vmod_command_int_callback( redisAsyncContext *rac, redisReply *reply, int *out ) {
	(void) rac;
	if( reply != NULL && reply->type == REDIS_REPLY_INTEGER ) *out = reply->integer;
}

int vmod_command_int( struct sess *sp, struct vmod_priv *global, const char *cmd, ... ) {
	g_return_val_if_fail(cmd != NULL, -1);
	dbgprintf(sp, "vmod_command_int: cmd = '%s'", cmd);

	RedisState *rs = redis_state(global);

	if( g_atomic_int_get(&rs->errored) ) {
		VSL(SLT_VCL_error, sp->id, "vmod_command_int: Skipping due to recorded error condition");
		return -1;
	}

	int val = -1;
	RedisResponseClosure rrc = {
		.func = (__typeof__(rrc.func)) vmod_command_int_callback,
		.data = &val
	};

	va_list ap, ap2;
	va_start(ap, cmd);
	va_copy(ap2, ap);

	if( !contains_null_strings(cmd, ap) )
		redis_command(rs, &rrc, cmd, ap2);

	va_end(ap);
	va_end(ap2);
	return val;
}

typedef struct {
	struct sess *sp;
	char *ret;
} VmodCommandStringCallbackArgs;

static void vmod_command_string_callback( redisAsyncContext *rac, redisReply *reply, VmodCommandStringCallbackArgs *args ) {
	(void) rac;
#ifndef NDEBUG
	dbgprintf(0, "vmod_command_string_callback: reply = %p", (void *) reply);
	if( reply != NULL ) {
		dbgprintf(0, "vmod_command_string_callback: reply->type = %d, REDIS_REPLY_STRING = %d", reply->type, REDIS_REPLY_STRING);
	}
#endif
	if( reply != NULL && reply->type == REDIS_REPLY_STRING )
		args->ret = WS_Dup(args->sp->wrk->ws, reply->str);
}

const char * vmod_command_string(struct sess *sp, struct vmod_priv *global, const char *cmd, ...) {
	g_return_val_if_fail(cmd != NULL, "");
	dbgprintf(0, "vmod_command_string: cmd = '%s'", cmd);

	RedisState *rs = redis_state(global);

	if( g_atomic_int_get(&rs->errored) ) {
		VSL(SLT_VCL_error, sp->id, "vmod_command_string: Skipping due to recorded error condition");
		return NULL;
	}

	VmodCommandStringCallbackArgs args = {
		.sp = sp,
		.ret = NULL
	};
	RedisResponseClosure rrc = {
		.func = (__typeof__(rrc.func)) vmod_command_string_callback,
		.data = &args
	};

	va_list ap, ap2;
	va_start(ap, cmd);
	va_copy(ap2, ap);

	if( !contains_null_strings(cmd, ap) )
		redis_command(rs, &rrc, cmd, ap2);

	va_end(ap);
	va_end(ap2);

	dbgprintf(0, "vmod_command_string: args.ret = '%s'", args.ret);
	return args.ret;
}
