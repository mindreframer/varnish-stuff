#include "vmod_backendutils.h"



/////////////
int
init_function(struct vmod_priv *priv, const struct VCL_conf *conf)
{

        return (0);
}
/*
struct director * vmod_getbackend(struct sess *sp, const char *name,struct director *defdirector){
	//検索
	for(int i=0; i < sp->vcl->ndirector; i++){
		syslog(6,"-------->%i %s",i,sp->vcl->director[i]->vcl_name);
		if(0 == strcmp(sp->vcl->director[i]->vcl_name, name)){
			return sp->vcl->director[i];
		}
	}
	//Todo: Add search to dynamic backend.
	//動的に作った方も検索対象に入れる
	
	struct backend *b;
	b = get_backend(name);
	if(b) return b;

	syslog(6,"homura<<<");
	return defdirector;

}
*/
struct director * vmod_createsimple(struct sess *sp, const char *name, const char *ip,const char * port){
	char*nname;nname=malloc(64);nname[0]=0;
	char*nip;nip=malloc(64);nip[0]=0;
	char nport[16];nport[0]=0;
	//todo: add assert(siz chk)
	strcpy(nname,name);
	strcpy(nip,ip);
	strcpy(nport,port);

	unsigned char      sockaddr[17];
	struct director    *directors[1];
	struct sockaddr_in inp;
	int iport = atoi(port);
	//Todo: Add assert(port range)
	//Todo: Support for ipv6
	inp.sin_family =AF_INET;
	inet_aton(nip, &(inp.sin_addr));
	
//	char nname[128];nname[0]=0;
//	char nip[64];nip[0]=0;
	
	sockaddr[0] =16;
	memcpy(&sockaddr[1],&inp,16);
	sockaddr[3] =iport & 0xff00;
	sockaddr[4] =iport & 0xff;
	struct vrt_backend backend = {
		.vcl_name            = nname,
		.ipv4_sockaddr       = sockaddr,
		.ipv4_addr           = nip,
		.port                = port,
		.hosthdr             = nip,
		.saintmode_threshold = -1,
	};
	
	VRT_init_dir_simple2(&directors, 0,(void*)&backend
		, ((struct vdi_simple *)(base_simple->priv))->dir.getfd
		, ((struct vdi_simple *)(base_simple->priv))->dir.fini
		, ((struct vdi_simple *)(base_simple->priv))->dir.healthy
	);
/*
	VRT_init_dir_simple2(&directors, 0,(void*)&backend
		, vdi_simple_getfd
		, vdi_simple_fini
		, vdi_simple_healthy
	);
*/	

	return directors[0];
}

void vmod_initsimple(struct sess *sp,struct director *simple){
	AZ(strcmp("simple", simple->name));
	base_simple = simple;
}
