#ifndef __HIREDIS_GLIB_H__
#define __HIREDIS_GLIB_H__

#include <glib.h>

#include <hiredis/hiredis.h>
#include <hiredis/async.h>

int redisGlibAttach(GMainContext *, redisAsyncContext *);
int redisGlibDetach(redisAsyncContext *);

#endif
