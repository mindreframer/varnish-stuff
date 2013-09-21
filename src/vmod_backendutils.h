#include <stdlib.h>
#include <stdio.h>
#include "vcl.h"
#include "vrt.h"
#include "bin/varnishd/cache.h"
#include "bin/varnishd/cache_backend.h"

#include <time.h>

#include <arpa/inet.h>
#include <syslog.h>
#include <poll.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <stdio.h>
#include "vcc_if.h"

#define FIND_TMO(tmx, dst, sp, be)		\
	do {					\
		dst = sp->wrk->tmx;		\
		if (dst == 0.0)			\
			dst = be->tmx;		\
		if (dst == 0.0)			\
			dst = params->tmx;	\
	} while (0)

struct vdi_simple {
	unsigned		magic;
#define VDI_SIMPLE_MAGIC	0x476d25b7
	struct director		dir;
	struct backend		*backend;
	const struct vrt_backend *vrt;
};

void VRT_init_dir_simple2(struct director **, int , const void *,vdi_getfd_f ,vdi_fini_f ,vdi_healthy );

static VTAILQ_HEAD(, backend) backends = VTAILQ_HEAD_INITIALIZER(backends);

static struct director *base_simple = NULL;

struct backend* get_backend(const char*,const char *,const char *);