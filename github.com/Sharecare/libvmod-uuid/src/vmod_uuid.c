/*
** Copyright 2013 Sharecare, Inc.
**
**   Licensed under the Apache License, Version 2.0 (the "License");
**   you may not use this file except in compliance with the License.
**   You may obtain a copy of the License at
**
**       http://www.apache.org/licenses/LICENSE-2.0
**
**   Unless required by applicable law or agreed to in writing, software
**   distributed under the License is distributed on an "AS IS" BASIS,
**   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
**   See the License for the specific language governing permissions and
**   limitations under the License.
**
**
** vmod_uuid.c  Generate a UUID for use by varnish
** Date:        08/23/2013
** By:          Mitchell Broome <mbroome@sharecare.com>
** Version:     0.1
**
**
*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <uuid.h>

#include <stdarg.h>
#include <syslog.h>

#include "vrt.h"
#include "bin/varnishd/cache.h"

#include "vcc_if.h"

void
debug(const char *fmt, ...){
   va_list ap;
   va_start(ap, fmt);
   vsyslog(LOG_DAEMON|LOG_INFO, fmt, ap);
   va_end(ap);
}

char 
*uuid_v1(void) {
    uuid_t *uuid;
    char *str;

    uuid_create(&uuid);
    uuid_make(uuid, UUID_MAKE_V1);
    str = NULL;
    uuid_export(uuid, UUID_FMT_STR, &str, NULL);
    uuid_destroy(uuid);
    //debug("uuid: %s", str);
    return(str);
}

int
init_function(struct vmod_priv *priv, const struct VCL_conf *conf){
   return(0);
}

const char *
vmod_uuid(struct sess *sp, struct vmod_priv *pv){
   char *p;
   unsigned u, v;

   char *uuid_str = uuid_v1();

   u = WS_Reserve(sp->wrk->ws, 0);     // Reserve some work space 
   if (sizeof(uuid_str) > u) {
      // No space, reset and leave 
      WS_Release(sp->wrk->ws, 0);
      return(NULL);
   }

   p = sp->wrk->ws->f;                 // Front of workspace area 

   strncpy(p, uuid_str, 37);
   // free up the uuid string once it's copied in place
   if(uuid_str){
      free(uuid_str);
   }

   // keep track of how much we actually used
   v+=37;

   // Update work space with what we've used 
   WS_Release(sp->wrk->ws, v);
//   debug("uuid: %s", p);
   return(p);
}

