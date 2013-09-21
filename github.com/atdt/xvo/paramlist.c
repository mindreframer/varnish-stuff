#include <stdio.h>
#include <stdlib.h>
#include "bstrlib.h"



struct tagbstring STRING_CONTAINS = bsStatic("string-contains");
struct tagbstring LIST_CONTAINS = bsStatic("list-contains");
struct tagbstring VALUE_OF = bsStatic("value-of");

#define MAX_VARY_OPTS 32
struct tagbstring SEP = bsStatic(",;");

struct parameter {
    struct tagbstring attr, val;
};

struct parameterList {
    bstring src;
    int qty, mlen;
    struct parameter ** entry;
};


/*
struct tagbstring
bstrVarnishHeader(struct sess *sp, const_bstring hdrname) {
*/
struct tagbstring
bstrVarnishHeader(const_bstring hdrname) {
    bstring hdrfmt;
    struct tagbstring hdrval;

    hdrfmt = bformat("%c%s:", hdrname->slen + 1, hdrname);
    /* btfromcstr(&bhdrval, VRT_GetHdr(sp, HDR_OBJ, hdrfmt->data)); */
    btfromcstr(hdrval, "gzip, x_sessionasdfUserID=123");
    bdestroy(hdrfmt);
    return hdrval;
}


struct parameter *
parseParam(const_bstring s) {
    struct parameter *param = NULL;
    int pos;
    
    param = malloc(sizeof(struct parameter));
    pos = bstrchr(s, '=');
    if (pos != BSTR_ERR) {
        btfromblktrimws(param->attr, s->data, pos);
        btfromblktrimws(param->val, s->data + pos + 1, s->slen - pos - 1);
    }
    return param;
}


static int
paramCb (void * parm, int ofs, int len) {
    struct parameterList *pl = (struct parameterList *) parm;
    struct tagbstring t;

    if (len == 0) {
        return 0;
    }
    if (pl->qty == pl->mlen) {
        return BSTR_ERR;
    }
    bmid2tbstr(t, pl->src, ofs, len);
    pl->entry[pl->qty] = parseParam(&t);
    pl->qty++;
    return 0;
}

/* struct parameterList */
struct parameterList *
parseParams(bstring hdrval) {
    struct parameterList *params;

    params = malloc(sizeof(struct parameterList));
    params->src = hdrval;
    params->qty = 0;
    params->mlen = MAX_VARY_OPTS;
    params->entry = malloc(MAX_VARY_OPTS * sizeof(struct parameter *));
    bsplitscb(params->src, &SEP, 0, paramCb, params);
    return params;
}

int
destroyParamList(struct parameterList *plst) {
    int i;
    for (i = 0; i < plst->qty; i++) {
        free(plst->entry[i]);
    }
    bdestroy(plst->src);
    free(plst->entry);
    free(plst);
    return 0;
}




int main(void) {
    char xvoHeader[] = "Cookie; string-contains=UserID; string-contains=_session, Accept-Encoding; list-contains=gzip";

    struct bstrList *parts, *conds;
    struct parameter *vo;
    struct parameterList *params;
    struct tagbstring hdrVal;
    bstring header, xvo;
    int i, j;

    xvo = bfromcstr(xvoHeader);
    if (!xvo) {
        return 1;
    }
    parts = bsplit(xvo, ',');
    bdestroy(xvo);
    if (parts == NULL) {
        return 1;
    }

    for (i = 0; i < parts->qty; i++) {
        conds = bsplit(parts->entry[i], ';');
        if (conds == NULL || conds->qty < 2) {
            continue;
        }
        header = conds->entry[0];
        btrimws(header);
        hdrVal = bstrVarnishHeader(header);
        params = parseParams(&hdrVal);

        for (j = 1; j < conds->qty; j++) {
            vo = parseParam(conds->entry[j]);
            if (bstricmp(&vo->attr, &STRING_CONTAINS) == 0) {
                printf("-------heyyyy, string contains\n");
            } else if (bstricmp(&vo->attr, &LIST_CONTAINS) == 0) {
                printf("yoooo, list contains\n");
            } else if (bstricmp(&vo->attr, &VALUE_OF) == 0) {
                printf("value of\n");
            }
            free(vo);
        }
        bstrListDestroy(conds);
        destroyParamList(params);
    }
    bstrListDestroy(parts);
    return 0;
}
