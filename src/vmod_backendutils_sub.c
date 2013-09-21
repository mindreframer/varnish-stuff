#include "vmod_backendutils.h"



void
bes_conn_try(const struct sess *sp, struct vbc *vc, const struct vdi_simple *vs)
{
	int s;
	struct backend *bp = vs->backend;

	CHECK_OBJ_NOTNULL(vs, VDI_SIMPLE_MAGIC);

	Lck_Lock(&bp->mtx);
	bp->refcount++;
	bp->n_conn++;		/* It mostly works */
	Lck_Unlock(&bp->mtx);

	s = -1;
	assert(bp->ipv6 != NULL || bp->ipv4 != NULL);

	/* release lock during stuff that can take a long time */

	if (params->prefer_ipv6 && bp->ipv6 != NULL) {
		s = vbe_TryConnect(sp, PF_INET6, bp->ipv6, bp->ipv6len, vs);
		vc->addr = bp->ipv6;
		vc->addrlen = bp->ipv6len;
	}
	if (s == -1 && bp->ipv4 != NULL) {
		s = vbe_TryConnect(sp, PF_INET, bp->ipv4, bp->ipv4len, vs);
		vc->addr = bp->ipv4;
		vc->addrlen = bp->ipv4len;
	}
	if (s == -1 && !params->prefer_ipv6 && bp->ipv6 != NULL) {
		s = vbe_TryConnect(sp, PF_INET6, bp->ipv6, bp->ipv6len, vs);
		vc->addr = bp->ipv6;
		vc->addrlen = bp->ipv6len;
	}

	vc->fd = s;
	if (s < 0) {
		Lck_Lock(&bp->mtx);
		bp->n_conn--;
		bp->refcount--;		/* Only keep ref on success */
		Lck_Unlock(&bp->mtx);
		vc->addr = NULL;
		vc->addrlen = 0;
	}
} 
int
vbe_TryConnect(const struct sess *sp, int pf, const struct sockaddr_storage *sa,
    socklen_t salen, const struct vdi_simple *vs)
{
	int s, i, tmo;
	double tmod;
	char abuf1[VTCP_ADDRBUFSIZE], abuf2[VTCP_ADDRBUFSIZE];
	char pbuf1[VTCP_PORTBUFSIZE], pbuf2[VTCP_PORTBUFSIZE];

	CHECK_OBJ_NOTNULL(sp, SESS_MAGIC);
	CHECK_OBJ_NOTNULL(vs, VDI_SIMPLE_MAGIC);

	s = socket(pf, SOCK_STREAM, 0);
	if (s < 0)
		return (s);

	FIND_TMO(connect_timeout, tmod, sp, vs->vrt);

	tmo = (int)(tmod * 1000.0);

	i = VTCP_connect(s, sa, salen, tmo);

	if (i != 0) {
		AZ(close(s));
		return (-1);
	}

	VTCP_myname(s, abuf1, sizeof abuf1, pbuf1, sizeof pbuf1);
	VTCP_name(sa, salen, abuf2, sizeof abuf2, pbuf2, sizeof pbuf2);
	WSL(sp->wrk, SLT_BackendOpen, s, "%s %s %s %s %s",
	    vs->backend->vcl_name, abuf1, pbuf1, abuf2, pbuf2);

	return (s);
}
unsigned int
vbe_Healthy(const struct vdi_simple *vs, const struct sess *sp)
{
	struct trouble *tr;
	struct trouble *tr2;
	struct trouble *old;
	unsigned i = 0, retval;
	unsigned int threshold;
	struct backend *backend;
	double now;

	CHECK_OBJ_NOTNULL(sp, SESS_MAGIC);
	CHECK_OBJ_NOTNULL(vs, VDI_SIMPLE_MAGIC);
	backend = vs->backend;
	CHECK_OBJ_NOTNULL(backend, BACKEND_MAGIC);

	if (backend->admin_health == ah_probe && !backend->healthy)
		return (0);

	if (backend->admin_health == ah_sick)
		return (0);

	/* VRT/VCC sets threshold to UINT_MAX to mark that it's not
	 * specified by VCL (thus use param).
	 */
	threshold = vs->vrt->saintmode_threshold;
	if (threshold == UINT_MAX)
		threshold = params->saintmode_threshold;

	if (backend->admin_health == ah_healthy)
		threshold = UINT_MAX;

	/* Saintmode is disabled, or list is empty */
	if (threshold == 0 || VTAILQ_EMPTY(&backend->troublelist))
		return (1);

	if (sp->objcore == NULL)
		return (1);

	now = sp->t_req;

	old = NULL;
	retval = 1;
	Lck_Lock(&backend->mtx);
	VTAILQ_FOREACH_SAFE(tr, &backend->troublelist, list, tr2) {
		CHECK_OBJ_NOTNULL(tr, TROUBLE_MAGIC);

		if (tr->timeout < now) {
			VTAILQ_REMOVE(&backend->troublelist, tr, list);
			old = tr;
			retval = 1;
			break;
		}

		if (!memcmp(tr->digest, sp->digest, sizeof tr->digest)) {
			retval = 0;
			break;
		}

		/* If the threshold is at 1, a single entry on the list
		 * will disable the backend. Since 0 is disable, ++i
		 * instead of i++ to allow this behavior.
		 */
		if (++i >= threshold) {
			retval = 0;
			break;
		}
	}
	Lck_Unlock(&backend->mtx);

	if (old != NULL)
		FREE_OBJ(old);

	return (retval);
}
int
vbe_CheckFd(int fd)
{
	struct pollfd pfd;

	pfd.fd = fd;
	pfd.events = POLLIN;
	pfd.revents = 0;
	return(poll(&pfd, 1, 0) == 0);
}
struct vbc *
vbe_NewConn(void)
{
	struct vbc *vc;

	ALLOC_OBJ(vc, VBC_MAGIC);
	XXXAN(vc);
	vc->fd = -1;
	Lck_Lock(&VBE_mtx);
	VSC_C_main->n_vbc++;
	Lck_Unlock(&VBE_mtx);
	return (vc);
}

void
copy_sockaddr(struct sockaddr_storage **sa, socklen_t *len,
    const unsigned char *src)
{

	assert(*src > 0);
	*sa = calloc(sizeof **sa, 1);
	XXXAN(*sa);
	memcpy(*sa, src + 1, *src);
	*len = *src;
}

struct backend *
VBE_AddBackend2( const struct vrt_backend *vb)
{
	struct backend *b;
	char buf[128];

	AN(vb->vcl_name);
	assert(vb->ipv4_sockaddr != NULL || vb->ipv6_sockaddr != NULL);


	/* Run through the list and see if we already have this backend */
	VTAILQ_FOREACH(b, &backends, list) {
		CHECK_OBJ_NOTNULL(b, BACKEND_MAGIC);
		if (strcmp(b->vcl_name, vb->vcl_name))
			continue;
		if (vb->ipv4_sockaddr != NULL && (
		    b->ipv4len != vb->ipv4_sockaddr[0] ||
		    memcmp(b->ipv4, vb->ipv4_sockaddr + 1, b->ipv4len)))
			continue;
		if (vb->ipv6_sockaddr != NULL && (
		    b->ipv6len != vb->ipv6_sockaddr[0] ||
		    memcmp(b->ipv6, vb->ipv6_sockaddr + 1, b->ipv6len)))
			continue;
		b->refcount++;
		b->vsc->vcls++;
		return (b);
	}

	/* Create new backend */
	ALLOC_OBJ(b, BACKEND_MAGIC);
	XXXAN(b);
	Lck_New(&b->mtx, lck_backend);
	b->refcount = 1;

	bprintf(buf, "%s(%s,%s,%s)",
	    vb->vcl_name,
	    vb->ipv4_addr == NULL ? "" : vb->ipv4_addr,
	    vb->ipv6_addr == NULL ? "" : vb->ipv6_addr, vb->port);

	b->vsc = VSM_Alloc(sizeof *b->vsc, VSC_CLASS, VSC_TYPE_VBE, buf);
	b->vsc->vcls++;

	VTAILQ_INIT(&b->connlist);

	VTAILQ_INIT(&b->troublelist);

	/*
	 * This backend may live longer than the VCL that instantiated it
	 * so we cannot simply reference the VCL's copy of things.
	 */
	REPLACE(b->vcl_name, vb->vcl_name);
	REPLACE(b->ipv4_addr, vb->ipv4_addr);
	REPLACE(b->ipv6_addr, vb->ipv6_addr);
	REPLACE(b->port, vb->port);

	/*
	 * Copy over the sockaddrs
	 */
	if (vb->ipv4_sockaddr != NULL)
		copy_sockaddr(&b->ipv4, &b->ipv4len, vb->ipv4_sockaddr);
	if (vb->ipv6_sockaddr != NULL)
		copy_sockaddr(&b->ipv6, &b->ipv6len, vb->ipv6_sockaddr);

	assert(b->ipv4 != NULL || b->ipv6 != NULL);

	b->healthy = 1;
	b->admin_health = ah_probe;

	VTAILQ_INSERT_TAIL(&backends, b, list);
	VSC_C_main->n_backend++;
	return (b);
}

/*--------------------------------------------------------------------*/

void
VRT_init_dir_simple2(struct director **bp, int idx,
	const void *priv,vdi_getfd_f vdi_simple_getfd,vdi_fini_f vdi_simple_fini,vdi_healthy vdi_simple_healthy)
{
	const struct vrt_backend *t;
	struct vdi_simple *vs;

//	ASSERT_CLI();
//	(void)cli;
	t = priv;

	ALLOC_OBJ(vs, VDI_SIMPLE_MAGIC);
	XXXAN(vs);
	vs->dir.magic = DIRECTOR_MAGIC;
	vs->dir.priv = vs;
	vs->dir.name = "simple";
	REPLACE(vs->dir.vcl_name, t->vcl_name);
	vs->dir.getfd = vdi_simple_getfd;
	vs->dir.fini = vdi_simple_fini;
	vs->dir.healthy = vdi_simple_healthy;

	vs->vrt = t;

	vs->backend = VBE_AddBackend2( t);
	if (vs->vrt->probe != NULL)
		VBP_Insert(vs->backend, vs->vrt->probe, vs->vrt->hosthdr);

	bp[idx] = &vs->dir;
}
/*
struct backend* get_backend(const char*vcl_name,const char *ip,const char *port)
{//todo : ip v4 only
	struct backend *b;
syslog(6,"--------d------------------------");
	VTAILQ_FOREACH(b, &backends, list) {
		CHECK_OBJ_NOTNULL(b, BACKEND_MAGIC);
		if(
			   0==strcmp(vcl_name,b->vcl_name)
			&& 0==strcmp(ip,b->ipv4_addr)
			&& 0==strcmp(port,b->port)
		
		){
syslog(6,"--------dhellod-%s",b->vcl_name);
			return(b);
		}
	}
	return NULL;
}
*/