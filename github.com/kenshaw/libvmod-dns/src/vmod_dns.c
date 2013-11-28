#include <stdlib.h>

#include <arpa/inet.h>
#include <netdb.h>

#ifdef __FreeBSD__
#include <netinet/in.h>
#include <stdio.h>
#endif

#include "vrt.h"
#include "bin/varnishd/cache.h"

#include "vcc_if.h"

#ifndef   NI_MAXHOST
#define   NI_MAXHOST 1025
#endif

int
init_function(struct vmod_priv *priv, const struct VCL_conf *conf) {
    return (0);
}

const char *
vmod_resolve(struct sess *sp, const char *str) {
    int error;
    struct addrinfo *ai;

    /* resolve the domain name */
    error = getaddrinfo(str, NULL, NULL, &ai);
    if (error != 0 || ai == NULL) {
        /* encountered an error, return empty string */
        return NULL;
    }

    char s[1024] = "";

    /* otherwise, we have a result */
    switch (ai->ai_addr->sa_family) {
        case AF_INET:
            inet_ntop(AF_INET, &(((struct sockaddr_in *) ai->ai_addr)->sin_addr), s, 1024);
            break;

        case AF_INET6:
            inet_ntop(AF_INET6, &(((struct sockaddr_in6 *) ai->ai_addr)->sin6_addr), s, 1024);
            break;

        defult:
            return NULL;
    }

    return s;
}

const char *
vmod_rresolve(struct sess *sp, const char *str) {
    struct sockaddr_in sa;

    sa.sin_family = AF_INET;
    inet_pton(AF_INET, str, &sa.sin_addr);

    char node[NI_MAXHOST];
    int res = getnameinfo((struct sockaddr*) &sa, sizeof(sa), node, sizeof(node), NULL, 0, 0);
    if (res != 0) {
        /* encountered an error, return empty string */
        return NULL;
    }

    char *s;
    unsigned u, v;

    /* Reserve some work space */
    u = WS_Reserve(sp->wrk->ws, 0);

    /* Front of workspace area */
    s = sp->wrk->ws->f;
    v = snprintf(s, u, "%s", node);
    v++;

    if (v > u) {
        /* No space, reset and leave */
        WS_Release(sp->wrk->ws, 0);
        return NULL;
    }

    /* Update work space with what we've used */
    WS_Release(sp->wrk->ws, v);
    return s;
}
