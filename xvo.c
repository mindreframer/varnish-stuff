#include <stdio.h>
#include <stdlib.h>
#include "bstrlib/bstrlib.h"



#define MAX_VARY_OPTS 32

struct tagbstring COMMA = bsStatic(", ");
struct tagbstring SEP = bsStatic(",;");
struct tagbstring STRING_CONTAINS = bsStatic("string-contains");
struct tagbstring LIST_CONTAINS = bsStatic("list-contains");
struct tagbstring BTRUE = bsStatic("true");
struct tagbstring BFALSE = bsStatic("false");


typedef struct Parameter {
    bstring attr;
    bstring val;
} Parameter;


Parameter *
parameterCreate(const_bstring raw) {
    Parameter *param = NULL;
    int i;
    
    i = bstrchr(raw, '=');
    if (i != BSTR_ERR) {
        param = malloc(sizeof(*param));
        param->attr = bmidstr(raw, 0, i);
        param->val = bmidstr(raw, i + 1, raw->slen);
        btrimws(param->attr);
        btrimws(param->val);
    }
    return param;
}

static void
parameterDestroy(Parameter *param) {
    if (param) {
        bdestroy(param->attr);
        bdestroy(param->val);
        free(param);
    }
}

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

static int
hdrStringContains(const_bstring header_val, const_bstring substring) {
    return binstr(header_val, 0, substring) != BSTR_ERR;
}

static int
hdrListContains(struct bstrList *list, const_bstring item) {
    int i;

    for (i = 0; i < list->qty; i++) {
        btrimws(list->entry[i]);
        if (biseq(list->entry[i], item)) {
            return 1;
        }
    }
    return 0;
}

static struct bstrList *
bstrListPreAllocCreate (int msz) {
    struct bstrList *sl;

    sl = malloc(sizeof(struct bstrList));
    if (sl == NULL) {
        return NULL;
    }
    sl->qty = 0;
    sl->entry = calloc(msz, sizeof(bstring));
    if (sl->entry == NULL) {
        free(sl);
        return NULL;
    }
    sl->mlen = msz;
    return sl;
}

static int
bstrListAdd(struct bstrList *sl, const_bstring str) {
    if (sl->qty == sl->mlen) {
        return BSTR_ERR;
    }
    sl->entry[sl->qty] = bstrcpy(str);
    sl->qty++;
    return BSTR_OK;
}

static bstring
formatVaryOpt(const_bstring header, Parameter *param, char *value) {
    return bformat("%s; %s-%s=%s", header->data, param->attr->data, param->val->data, value);
}

static int
cmpVaryOpts(const void *a, const void *b) {
    return bstricmp(a, b);
}


int main(void) {
    char xvoHeader[] = "Cookie; string-contains=UserID; string-contains=_session, Accept-Encoding; list-contains=gzip";

    struct tagbstring hdrVal;
    struct bstrList *parts, *conds, *varied, *hparams;
    Parameter *vo = NULL;
    bstring xvo;
    bstring header;
    bstring opt;
    bstring variedstr;

    int i, j, k;

    xvo = bfromcstr(xvoHeader);
    if (!xvo) {
        return 1;
    }
    parts = bsplit(xvo, ',');
    bdestroy(xvo);
    if (parts == NULL) {
        return 1;
    }

    varied = bstrListPreAllocCreate(MAX_VARY_OPTS);
    if (varied == NULL) {
        return 1;
    }

    for (i = 0; i < parts->qty; i++) {
        conds = bsplit(parts->entry[i], ';');
        if (conds == NULL || conds->qty < 2) {
            continue;
        }

        header = conds->entry[0];
        btrimws(header);
        /* bstring hdrVal = bstrVarnishHeader(sp, conds->entry[0]); */
        hdrVal = bstrVarnishHeader(conds->entry[0]);
        hparams = bsplits(&hdrVal, &SEP);

        for (j = 1; j < conds->qty; j++) {
            vo = parameterCreate(conds->entry[j]);

            if (bstricmp(vo->attr, &STRING_CONTAINS) == 0) {
                opt = formatVaryOpt(header, vo, hdrStringContains(&hdrVal, vo->val) ? "1" : "0");
                bstrListAdd(varied, opt);
                bdestroy(opt);
            } else if (bstricmp(vo->attr, &LIST_CONTAINS) == 0) {
                opt = formatVaryOpt(header, vo, hdrListContains(hparams, vo->val) ? "1" : "0");
                bstrListAdd(varied, opt);
                bdestroy(opt);
            }
            parameterDestroy(vo);
        }
        bstrListDestroy(conds);
        bstrListDestroy(hparams);
    }
    bstrListDestroy(parts);

    qsort(varied->entry, varied->qty, sizeof(bstring), cmpVaryOpts);

    variedstr = bjoin(varied, &COMMA);
    /* VRT_SetHdr(sp, HDR_REQ, "\014X-Varied-On:", variedstr->data, vrt_magic_string_end); */
    printf("X-Varied-On: %s\n", variedstr->data);
    bdestroy(variedstr);

    for (k = 0; k < varied->qty; k++) {
        /* VRT_hashdata(sp, varied->entry[j]->data, vrt_magic_string_end); */
        printf("- %s\n", varied->entry[k]->data);
    }

    bstrListDestroy(varied);
    return 0;
}

