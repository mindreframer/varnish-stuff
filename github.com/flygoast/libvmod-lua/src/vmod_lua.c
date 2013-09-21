#include <stdlib.h>
#include <stdio.h>
#include <sys/time.h>

#include "vrt.h"
#include "bin/varnishd/cache.h"

#include "vcc_if.h"

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"


#define	LOG_E(...) fprintf(stderr, __VA_ARGS__);
#ifdef DEBUG
# define LOG_T(...) fprintf(stderr, __VA_ARGS__);
#else
# define LOG_T(...) do {} while(0);
#endif


typedef struct lua_config {
    lua_State  *L;
} lua_config_t;


static lua_config_t *
make_config(void)
{
    lua_config_t *cfg;

    LOG_T("make_config()\n");

    cfg = malloc(sizeof(lua_config_t));
    if(cfg == NULL) {
        return NULL;
    }

    cfg->L = luaL_newstate();
    luaL_openlibs(cfg->L);

    return cfg;
}


static void
free_config(lua_config_t *cfg)
{
    if (cfg) {
        lua_close(cfg->L);
        free(cfg);
    }
}


int
init_function(struct vmod_priv *priv, const struct VCL_conf *conf)
{
    LOG_T("lua init_function called\n");

    priv->free = (vmod_priv_free_f *)free_config;

    return 0;
}


void
vmod_init(struct sess *sp, struct vmod_priv *priv)
{
    if (priv->priv) {
        free_config(priv->priv);
    }

    priv->priv = make_config();
}


void
vmod_dofile_void(struct sess *sp, struct vmod_priv *priv, const char *filename)
{
    lua_config_t  *cfg = priv->priv;

    if (luaL_dofile(cfg->L, filename) != 0) {
        LOG_E("luaL_dofile(\"%s\") failed, errstr=\"%s\"\n", 
              filename, luaL_checkstring(cfg->L, -1));
        lua_pop(cfg->L, 1);
    }
}


int
vmod_dofile_int(struct sess *sp, struct vmod_priv *priv, const char *filename)
{
    int            ret;
    lua_config_t  *cfg = priv->priv;

    if (luaL_loadfile(cfg->L, filename) != 0) {
        LOG_E("luaL_loadfile(\"%s\") failed, errstr=\"%s\"\n",
              filename, luaL_checkstring(cfg->L, -1));
        lua_pop(cfg->L, 1);
        return -1;
    }

    if (lua_pcall(cfg->L, 0, 1, 0) != 0) {
        LOG_E("lua_pcall(\"%s\") failed, errstr=\"%s\"\n",
              filename, luaL_checkstring(cfg->L, -1));
        lua_pop(cfg->L, 1);
        return -1;
    }

    ret = luaL_checkint(cfg->L, 1);
    lua_pop(cfg->L, 1);

    return ret;
}


const char *
vmod_dofile_str(struct sess *sp, struct vmod_priv *priv, const char *filename)
{
    const char    *ret;
    lua_config_t  *cfg = priv->priv;

    if (luaL_loadfile(cfg->L, filename) != 0) {
        LOG_E("luaL_loadfile(\"%s\") failed, errstr=\"%s\"\n",
              filename, luaL_checkstring(cfg->L, -1));
        lua_pop(cfg->L, 1);
        return NULL;
    }

    if (lua_pcall(cfg->L, 0, 1, 0) != 0) {
        LOG_E("lua_pcall(\"%s\") failed, errstr=\"%s\"\n",
              filename, luaL_checkstring(cfg->L, -1));
        lua_pop(cfg->L, 1);
        return NULL;
    }

    if ((ret = luaL_checkstring(cfg->L, 1)) == NULL) {
        LOG_E("luaL_checkstring() failed");
        lua_pop(cfg->L, 1);
        return NULL;
    }

    ret = WS_Dup(sp->wrk->ws, ret);
    if (ret == NULL) {
        LOG_E("WS_Dup failed");
        lua_pop(cfg->L, 1);
        return NULL;
    }

    lua_pop(cfg->L, 1);

    return ret;
}
