#include <stdlib.h>

#include "vrt.h"
#include "bin/varnishd/cache.h"

#include "vcc_if.h"

#include <sys/socket.h>
#include <netdb.h>

int
init_function(struct vmod_priv *priv, const struct VCL_conf *conf) {
	return (0);
}

int vmod_clientip(struct sess *sp, const char *ipstring) {
	struct addrinfo hints;
	struct addrinfo *rp;
	int s;

	AN(sp);
	AN(ipstring);

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;

	// Don't attempt DNS resolution.
	hints.ai_flags = AI_NUMERICHOST;

	s = getaddrinfo(ipstring, NULL, &hints, &rp);
	if (s != 0) {
		VSL(SLT_VCL_Log, 0, "ipcast: Unable to decode IP address '%s'",
				ipstring);
		VSL(SLT_VCL_Log, 0, "ipcast: getaddrinfo(): %s", gai_strerror(s));
		return(s);
	}
	AN(rp);

	sp->sockaddrlen = rp->ai_addrlen;
	memcpy(sp->sockaddr, rp->ai_addr, rp->ai_addrlen);

	freeaddrinfo(rp);
	return(0);
}
