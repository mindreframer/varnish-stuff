/*-
 * Copyright (c) 2012 Jeremy Thomerson, Expert Tech Services, LLC
 * All rights reserved.
 *
 * Author: Jeremy Thomerson <jeremy@thomersonfamily.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <stdlib.h>

#include "vrt.h"
#include "bin/varnishd/cache.h"
#include "include/vct.h"

#include "vcc_if.h"
#include "config.h"

/*
 * vmod entrypoint. Sets up the module
 */
int
init_function(struct vmod_priv *priv __attribute__((unused)),
	      const struct VCL_conf *conf __attribute__((unused)))
{
	return (0);
}

const char * __match_proto__()
vmod_version(struct sess *sp __attribute__((unused)))
{
	return VERSION;
}

const char * __match_proto__()
vmod_expires_from_cache_control(struct sess *sp, double default_duration)
{
	char *header = VRT_GetHdr(sp, HDR_RESP, "\016cache-control:");
	int max_age = -1;
	if (header) {
		while (*header != '\0') {
			if (*header == 'm' && !memcmp(header, "max-age=", 8)) {
				header += 8;
				max_age = strtoul(header, 0, 0);
				break;
			}
			header++;
		}
	}
	return vmod_rfc_format(sp, (TIM_real() + (max_age == -1 ? default_duration : max_age)));
}

const char * __match_proto__()
vmod_rfc_format(struct sess *sp, double seconds_since_epoch)
{
	char *u;
	u = WS_Alloc(sp->wrk->ws, TIM_FORMAT_SIZE);
	if (u == NULL) {
		return (NULL);
	}
	TIM_format(seconds_since_epoch, u);
	return u;
}
