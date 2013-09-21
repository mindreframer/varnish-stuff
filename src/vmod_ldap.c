#include <stdlib.h>
#include "vcl.h"
#include "vrt.h"
#include "bin/varnishd/cache.h"
#include <syslog.h>
#include <stdio.h>
#include "vcc_if.h"

#include <ldap.h>


#define VMODLDAP_HDR "\020X-VMOD-LDAP-PTR:"

struct vmod_ldap {
	unsigned			magic;
#define VMOD_LDAP_MAGIC 0x8d4f21ef
	LDAP        *ld;
	LDAPMessage *searchResult;
	char        *user;
	int         userlen;
	const char  *dn;
	int         dnlen;
	int         result;
	char        *pass;
};


static vcl_func_f         *vmod_Hook_deliver = NULL;
static unsigned           hook_done = 0;

void hookFunc(struct sess *);
static int vmod_Hook_unset_deliver(struct sess *);
static pthread_mutex_t    vmod_mutex = PTHREAD_MUTEX_INITIALIZER;
void vmodldap_free(struct sess *);
struct vmod_ldap *vmodldap_get_raw(struct sess *);
struct vmod_ldap *vmodldap_init(struct sess *, const char*, const char*);
//////////////////////////////////////////////////
//base64 based on libvmod-digest
//
//https://github.com/varnish/libvmod-digest
//////////////////////////////////////////////////
enum alphabets {
	BASE64 = 0,
	BASE64URL = 1,
	BASE64URLNOPAD = 2,
	N_ALPHA
};

static struct e_alphabet {
	char *b64;
	char i64[256];
	char padding;
} alphabet[N_ALPHA];


static void
vmod_digest_alpha_init(struct e_alphabet *alpha)
{
	int i;
	const char *p;

	for (i = 0; i < 256; i++)
		alpha->i64[i] = -1;
	for (p = alpha->b64, i = 0; *p; p++, i++)
		alpha->i64[(int)*p] = (char)i;
	if (alpha->padding)
		alpha->i64[alpha->padding] = 0;
}
static int
base64_decode(struct e_alphabet *alpha, char *d, unsigned dlen, const char *s)
{
	unsigned u, v, l;
	int i;

	u = 0;
	l = 0;
	while (*s) {
		for (v = 0; v < 4; v++) {
			if (*s)
				i = alpha->i64[(int)*s++];
			else
				i = 0;
			if (i < 0)
				return (-1);
			u <<= 6;
			u |= i;
		}
			
		for (v = 0; v < 3; v++) {
			if (l >= dlen - 1)
				return (-1);
			*d = (u >> 16) & 0xff;
			u <<= 8;
			l++;
			d++;
		}
		if (!*s)
			break;
	}
	*d = '\0';
	l++;
	return (l);
}

int
init_function(struct vmod_priv *priv, const struct VCL_conf *conf)
{
    alphabet[BASE64].b64 =
		"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef"
		"ghijklmnopqrstuvwxyz0123456789+/";
	alphabet[BASE64].padding = '=';
	alphabet[BASE64URL].b64 =
		 "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef"
		 "ghijklmnopqrstuvwxyz0123456789-_";
	alphabet[BASE64URL].padding = '=';
	alphabet[BASE64URLNOPAD].b64 =
		 "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef"
		 "ghijklmnopqrstuvwxyz0123456789-_";
	alphabet[BASE64URLNOPAD].padding = 0;
	vmod_digest_alpha_init(&alphabet[BASE64]);
	vmod_digest_alpha_init(&alphabet[BASE64URL]);
	vmod_digest_alpha_init(&alphabet[BASE64URLNOPAD]);
	return (0);
}

//////////////////////////////////////////////////


//hook vcl_deliver
void hookFunc(struct sess *sp){
	
	//disable hook
	return;
	
	if(hook_done == 1 && sp->vcl->deliver_func != vmod_Hook_unset_deliver) hook_done = 0;
	
	if(hook_done == 0){
		AZ(pthread_mutex_lock(&vmod_mutex));
		if(hook_done == 0){

			vmod_Hook_deliver		= sp->vcl->deliver_func;
			sp->vcl->deliver_func	= vmod_Hook_unset_deliver;
			hook_done = 1;

		}
		AZ(pthread_mutex_unlock(&vmod_mutex));
	}
}

static int vmod_Hook_unset_deliver(struct sess *sp){
	int ret = vmod_Hook_deliver(sp);
	struct vmod_ldap *c;
	c = vmodldap_get_raw(sp);
	if(c) vmodldap_free(sp);
	return(ret);

}

//parse for Basic Authorization header
void parseAuthHeader(struct sess *sp, char** user, char** pass){
	hookFunc(sp);
	*user = 0;
	*pass = 0;
	const char *tmp;
	tmp = VRT_GetHdr(sp, HDR_REQ, "\016Authorization:");
	if(tmp == NULL) return;
	if(strncmp(tmp,"Basic ",6) != 0) return;
	tmp +=6;
	
	int u;
	char *p,*pa;
	u = WS_Reserve(sp->wrk->ws,0);
	p = sp->wrk->ws->f;
	u = base64_decode(&alphabet[BASE64], p,u,tmp);
	if (u < 0) {
		WS_Release(sp->wrk->ws,0);
		return;
	}
	pa = strstr(p,":");
	if(pa == NULL){
		WS_Release(sp->wrk->ws,0);
		return;
	}
	pa[0] = 0;
	++pa;
	*user = p;
	*pass = pa;
	WS_Release(sp->wrk->ws,u);
}


struct vmod_ldap *vmodldap_get_raw(struct sess *sp){
	const char *tmp;
	struct vmod_ldap *c;

	tmp = VRT_GetHdr(sp, HDR_REQ, VMODLDAP_HDR);
	
	if(tmp){
		c = (struct vmod_ldap *)atol(tmp);
		return c;
	}
	return NULL;
}

struct vmod_ldap *vmodldap_init(struct sess *sp, const char*user, const char*pass){
	struct vmod_ldap *c;
	int passlen;
	char buf[64];
	buf[0] = 0;
	ALLOC_OBJ(c, VMOD_LDAP_MAGIC);
	AN(c);
	snprintf(buf,64,"%ld",c);
	
	passlen = strlen(pass);
	c->userlen = strlen(user);
	c->user = calloc(1, c->userlen +1);
	AN(c->user);
	memcpy(c->user, user ,c->userlen);
	
	c->pass = calloc(1, passlen +1);
	AN(c->pass);
	memcpy(c->pass, pass ,passlen);

	VRT_SetHdr(sp, HDR_REQ, VMODLDAP_HDR, buf, vrt_magic_string_end);
	return c;
}
void vmodldap_free(struct sess *sp){
	struct vmod_ldap *c;
	c = vmodldap_get_raw(sp);
	if(!c) return;
	if(c->ld) ldap_unbind_s(c->ld);
	if(c->searchResult) ldap_msgfree(c->searchResult);
	if(c->user) free(c->user);
	if(c->pass) free(c->pass);
	FREE_OBJ(c);
	VRT_SetHdr(sp, HDR_REQ, VMODLDAP_HDR, 0);
}

//////////////////////////////////////////////////

//get user name from Authorization header
const char* vmod_get_basicuser(struct sess *sp){
	char *user,*pass;
	parseAuthHeader(sp,&user,&pass);
	
	return user;
}

//get pass from Authorization header
const char* vmod_get_basicpass(struct sess *sp){
	char *user,*pass;
	
	parseAuthHeader(sp,&user,&pass);
	
	return pass;
}

//init ldap connection
unsigned vmod_open(struct sess *sp, unsigned V3, const char* basedn, const char*basepw, const char*searchdn, const char*user, const char *pass){

	hookFunc(sp);

	AN(basedn);
	AN(basepw);
	unsigned res = (0==1);
	if(user == NULL) return res;
	if(pass == NULL) return res;
	
	struct vmod_ldap *c;
	c = vmodldap_get_raw(sp);
	if(c) vmodldap_free(sp);//前の接続の切断
	c = vmodldap_init(sp,user,pass);
	
	int ret;
	struct timeval timeOut = { 10, 0 };
	
	LDAPURLDesc *ludpp;
	int filterlen = 0;
	char *filter;
	int version;
	char *host;
	//URLパース
	ret = ldap_url_parse(searchdn, &ludpp);
	if(ret != LDAP_SUCCESS){
		syslog(6,"ldap_url_parse: %d, (%s)", ret, ldap_err2string(ret));
		ldap_free_urldesc(ludpp);
		return res;
	}
	
	host = calloc(1,strlen(searchdn)+4);
	sprintf(host,"%s://%s:%d/", ludpp->lud_scheme,ludpp->lud_host,ludpp->lud_port);
	//接続
	ret = ldap_initialize(&c->ld, host);
	if(ret != LDAP_SUCCESS){
		syslog(6,"ldap_initialize: %d, (%s)", ret, ldap_err2string(ret));
		vmodldap_free(sp);
		ldap_free_urldesc(ludpp);
		free(host);
		return res;
	}
	free(host);
	//V3認証
	if(V3){
		version = LDAP_VERSION3;
		ldap_set_option(c->ld, LDAP_OPT_PROTOCOL_VERSION, &version );
		if(ret != LDAP_SUCCESS){
			syslog(6,"ldap_set_option: %d, (%s)", ret, ldap_err2string(ret));
			vmodldap_free(sp);
			ldap_free_urldesc(ludpp);
			return res;
		}
	}
	//base認証
	ret = ldap_simple_bind_s(c->ld,basedn,basepw);
	if(ret != LDAP_SUCCESS){
		syslog(6,"ldap_simple_bind_s: %d, (%s)", ret, ldap_err2string(ret));
		vmodldap_free(sp);
		ldap_free_urldesc(ludpp);
		return res;
	}

	//文字列長調整
	if(ludpp->lud_filter){
		filterlen += strlen(ludpp->lud_filter);
	}else{
		filterlen += 15;//"(objectClass=*)"
	}
	filterlen += strlen(ludpp->lud_attrs[0]);
	filterlen += strlen(user);
	filter = calloc(1,filterlen +1);
	sprintf(filter,"(&%s(%s=%s))", ludpp->lud_filter != NULL ? ludpp->lud_filter : "(objectClass=*)", ludpp->lud_attrs[0], user);

	//リスト取得
	ret = ldap_search_ext_s(c->ld, ludpp->lud_dn, ludpp->lud_scope, filter, NULL, 0, NULL, NULL, &timeOut, 0,&c->searchResult);
	if(ret != LDAP_SUCCESS){
		syslog(6,"ldap_search_ext_s: %d, (%s)", ret, ldap_err2string(ret));
		vmodldap_free(sp);
	}else if(ldap_count_entries(c->ld, c->searchResult) > 0) {
		c->dn = ldap_get_dn(c->ld, c->searchResult);
		c->dnlen = strlen(c->dn);
		res = (1==1);
	}
	free(filter);
	ldap_free_urldesc(ludpp);
	c->result = (int)res;
	return res;

}

//compare dn with val
unsigned vmod_require_user(struct sess *sp,const char *val){
	struct vmod_ldap *c;
	c = vmodldap_get_raw(sp);
	unsigned res = (0==1);
	int ret;
	if(!c) return res;
	if(!c->result) return res;
	if(strncmp(val,c->dn,strlen(val)) == 0) res = (1==1);
	return res;
}

//compare
unsigned vmod_compare(struct sess *sp,const char *val,const char *attr){
	struct vmod_ldap *c;
	c = vmodldap_get_raw(sp);
	unsigned res = (0==1);
	int ret;
	if(!c) return res;
	if(!c->result) return res;
	
	struct berval bvalue;
	bvalue.bv_val = c->user;
	bvalue.bv_len = c->userlen;
	ret = ldap_compare_ext_s(c->ld, val, attr,&bvalue, NULL, NULL);
	if(ret == LDAP_COMPARE_TRUE) res = (1==1);
	return res;
}

//compare(use DN)
unsigned vmod_compare_dn(struct sess *sp,const char *val,const char *attr){
	struct vmod_ldap *c;
	c = vmodldap_get_raw(sp);
	unsigned res = (0==1);
	int ret;
	if(!c) return res;
	if(!c->result) return res;
	
	struct berval bvalue;
	bvalue.bv_val = (char*)c->dn;
	bvalue.bv_len = c->dnlen;
	ret = ldap_compare_ext_s(c->ld, val, attr,&bvalue, NULL, NULL);
	if(ret == LDAP_COMPARE_TRUE) res = (1==1);
	return res;
}

//compare to attr
unsigned vmod_compare_attribute(struct sess *sp,const char *val,const char *attr){
	struct vmod_ldap *c;
	c = vmodldap_get_raw(sp);
	unsigned res = (0==1);
	int ret;
	if(!c) return res;
	if(!c->result) return res;
	
	struct berval bvalue;
	bvalue.bv_val = (char*)val;
	bvalue.bv_len = strlen(val);
	ret = ldap_compare_ext_s(c->ld, c->dn, attr,&bvalue, NULL, NULL);
	if(ret == LDAP_COMPARE_TRUE) res = (1==1);
	return res;
}

//bind
unsigned vmod_bind(struct sess *sp){
	struct vmod_ldap *c;
	c = vmodldap_get_raw(sp);
	unsigned res = (0==1);
	int ret;
	if(!c) return res;
	if(!c->result) return res;

	ret = ldap_simple_bind_s(c->ld, c->dn, c->pass);
	if(ret == LDAP_SUCCESS) res =(1==1);
	
	return res;
}


const char* vmod_get_dn(struct sess *sp){
	struct vmod_ldap *c;
	c = vmodldap_get_raw(sp);
	if(!c) return NULL;
	if(!c->result) return NULL;
	
	return c->dn;
}

void vmod_close(struct sess *sp){
	struct vmod_ldap *c;
	c = vmodldap_get_raw(sp);
	if(!c) return;
	vmodldap_free(sp);
}

unsigned vmod_simple_auth(struct sess *sp,unsigned V3,const char* basedn,const char*basepw,const char*searchdn,const char*user,const char*pass){

	unsigned res;
	vmod_open(sp, V3, basedn, basepw, searchdn, user, pass);
	res = vmod_bind(sp);
	vmod_close(sp);
	return res;
}


