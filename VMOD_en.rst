.. contents::
   :class: handout
   
.. raw:: pdf

   PageBreak oneColumn

﻿
Contents
subject ofdocument	2

#highly customizableofVarnish	two-line
#basic knowledge necessary when using the C	4
#dump ofVCL	4
#Read the source ofVarnish	7-line
#methodthat perform the variable operation at  C	12
#to use thebuilt-in functions	18-line
#CWhen using external shared libraries	22
#basic knowledge necessary when using theVMOD	24
(vmod_example)to try using the VMOD ofexternal	24vmod
you try to add a functionto	vmod_example.vcc
25(vmod.vcc)vmod_example.	26
c (vmod.c)	27(varnishtest
#typeof variables availableinVMOD	28
usesession workspace	34
How to private pointer	36
to use external shared libraries inVMOD	41
that use regular expressions inVMOD	42
How to debugVMODdocument)	43
News	44
Afterword	44

Introduction
============

this bookis targeted towards the following.
-Thatvarious-inthat was utilized (hereinafter Varnish) Varnish Cache
way of using tools Varnish  (such as varnishlog) understood
sometimeshastouched a language · C
it is uneasy to the use of the Varnish wouldis yet-no The person, I recommend reading are included in this CD pros and cons of "VarnishCache Getting Started".
Thehas been carried out in the following
OSenvironment:Scientific:	 Linux6
Varnish3.0.2


Advanced Varnish Customization
==============================

VCL DSL (Domain Specific Language) is equipped withVarnish degrees of freedom very like doing the programming just setting high is possible.
However,and the new definition of a variable, type conversion of some of the variables and may not be able to in the VCL,
itMuzugayui little restriction exists is also true. It offers a solution of the following two in Varnish in order to avoid this limitation.
-Inin-lineC
· Varnish Module (below VMOD)
a way that can be written in the C language in VCL literally, line C is the function to be able to feel a bit of additional functions.
For example, can be written as follows: When outputting the syslog when received from the backend 503.
/ / Beginning of the file
C <syslog.h>}
  {#include
C
/ / ~ snip vcl_fetch(beresp.status
sub{if
  ~  == (LOG_INFO,503
    {C
      503){syslog "Statusurl =% s", VRT_r_req_url (deliver);
    C}
  (sp));}
  return
in}
places enclosed  C {~} C is inline C. You can see it feel free to write very like this.
But let's think a little here. But what if the code is long if?
And to include it to go out to a file or it is there but it is not a very smart. Even if there have been a function of, must be written in-line C when you call.
For example,VRT_r_req_url and (sp),if you want to get in-line C the value of
there is a difficulty to maintenance of the codefor example, have to writereq.url.
In addition, others require you to write or the module you want to link cc_command of startup parameters or if there is a need to link to other shared libraries.
So Another solution is VMOD.
It has been gathered in the module as the name, there is no need to write inline C even when using the VCL.
For example, you do the following for the output of syslog use the VMOD of std that is distributed in the standard.
if;}import
{(beresp.status{std.syslogreq.url)sub
  == (6,503 (deliver);}
    503) "Statusurl =" +vcl_fetch;
  
  return

I am very easy to understandstd.
In How do should I Tsukaiwakere is VMOD inline and C?
This is my opinion, but personally, I have summarized below.
inline C
case-specificrewrite occurs· frequently
case,it is not only used in the flow of
relatively light processing
VMOD
case, externaloccupies a· function
if, withinto use the shared library in the
Shared resources in a module, or  a functionifyou want to use
case,the initialization and termination processingis
Are there any criteria also various otherrequired,but want to hold the above-mentioned items.
The knowledge of the various functions of Varnish and specific C language is a required way to use either.
I will discuss the next chapter.

Basic Required Knowledge When Using in-line C
=============================================
I can not say a detailed document and are substantial in using the inline C The documentation for the officialC.Therefore,to remember the notation
to analyze it to dump the VCL
read the source of Varnish
you must have prepared andbasically.
It describes the point on having read the source and method of actually dumped.

VCL Dump
--------

Code when it is converted to C VCL is output when the following steps are thecommand ofVarnish
Code output will be very helpful in writing inline C. You can get the same behavior even if enclosed in C {~} C content that is output as it is of course.

Command

varnishd-d-f [VCL file name]-C

VCL

 1  default  = "81";}backend{host = "192.168.1.199";.. Port
  backend{host = "192.168.1.199";.. Port2admin vcl_recv(req.url"^/")req.backend =
  3
  4 =sub{·{·{					· ·  · ·
  5         (1)if~  /  admin;			(2)
  admin6 set
  "82";}7}else
  8req.backend                 set= (lookup);		· · ·
  9}
 10         default;(3)return				... (4)
 11}

VCL, which isconversion sp)

444 static int
445 (excerpt)VGC_function_vcl_recv (struct sess *			· · · ('input'5) 1);(452(VRT_r_req_url(sp),
446
(1)/ * ... from  Line 4 Pos  * /
{447448
{449
{450VRT_count
451       if
         (sp,VRT_re_match VGC_re_2 453)2);457);3);		· · ·  (sp,(_admin)(sp,(sp,
       )
454 {461
(2)VRT_count VRT_count
(sp,456 VGCDIR VRT_l_req_backend

458}
459 else
{455460

462           VRT_l_req_backendVGCDIR(3)463);(sp, (4)('Default'5)	· · · · ·
(_default)VCL_RET_LOOKUP);
464}
465       VRT_done				·
466}
467}
468 / * ... from  Line 40 Pos  * /
469
{470
{471VRT_count  (sp)0)
(sp,472 if
4);(473 (VRT_r_req_restarts==
snip

539)13);VCL_RET_PASS);

540
538){541VRT_count (sp,
(sp, 542 VRT_done
543 }
544 VRT_count  (sp, VRT_done;
(sp, 14);VCL_RET_LOOKUP)545
546}
547}
548}
549

number next to the VCL that has been convertedandVCL is the corresponding row.
Make sure over the conversion to C after I wrote normally the VCL in this way, how to respond.
Code is conversion consists of a block as follows.
The number of lines uncommentedonly the definition of the backend of default.vcl that is
issupported when you convert those distributed.
(Line: 1-399) definition of the structure, constant, various
variables,such as the definition of the structure of directors and back-end are described.
There is also a definition of such as a function to use when you read and write variables such as req.url.
Definitions such as variable or regular expression backend · ACL (line: 400-424)
such as ACL and back end you defined are defined.
Action definition (such as vcl_recv) (line: 425-691)
actions defined vcl_recv such as has been described.
Contains blocks as lesseach action
static int VGC_function_ [action name] (struct sess  sp)*
{/
*... from('input' Line [line number] Pos [position number]) * /
content ~you converted to C the VCL-user-input
([position/ * ... from'Default' * / number]Line [line number] Pos)
content  the thewas converted to C VCL of~ default
~}

nameofactionand vcl_fetch and vcl_recv will contain.
And line number, position numbertheVCL and the input of the user (input)
matches  number of characters from the beginning of the line with the content or from the row number of VCL throat defaultof the (default).
Also, as you can see here,alwaysafter the VCL entered by the
VCL the default isembeddeduser.In each action for that, VCL the default behavior if you do not return, etc. (lookup) explicitly, is subject to change and movement you have in mind.
VRT_count table (line: 692 ~ 719)
Varnish is to trace the behavior of the VCL. I insert the VRT_count function in place that branches of processing, such as if statements and the start of the action for that.
This number is a table of what the place of VCL throat.
VCL:constructor destructor of VCL (720 ~ 736
vcl_init / vcl_finiin what will be called during the initialization, at the end of the  This
Is unrelated to theactionline).
I have carried out such as loading VMOD and compile the regular expression.
VCL source of the converted (line: 737 ~ 1022)
VCL the default VCL and user-written have been written.
(Line: 1023-1047) set of VCL
configuration of the VCL Varnish is used during processing contains.

Reading the Varnish source
--------------------------

You can write a VCL description of every Varnish,and to confirm by converting to C is tedious very.
Look at all the source of Varnish, and to understand to say whether it is very difficult.
In addition, it is not less desirable, butthat tricky to use skillfully the function of
you must move the Varnish also minimum grasp on it, such asinternal,to perform advanced processing. I will explain how to read the source and where a point.
/lib / libvcl / generate.py
Content very important return values ​​of various actions to be used inVCL, such as a list and the type variable is described. This file contains the following content.
token list ofVCL.
And operators that are available are defined in thetokens
available Return Valuesaction (such as
It is defined in the​​returnsvcl_recv).
('Pipe', ('error', 'pipe',)),	
the above's represents is, it is that you can specify the pipe error and when you return in vcl_pipe.

listof
where the action is each a list of variables, such as thereq.url sp_variables
How and the type and name availability is defined as follows:variable.
('Bereq.between_bytes_timeout',	/ / variable name
	'DURATION',			type of variable / /
	('pass', 'miss',),			read / / variable possible actions list
	('pass', 'miss', ),			whenwriting / / variable  action listpossible),
	'struct sess *'			Prefix of function arguments to/ / read / write
value
afor the action,allvcl_ini all and that can be used in all actions, the vcl_fini
in  butThere is a proc that can be used.
storage variable list
VCLvariable of storage are defined in thestv_variables.
typelist of variables in the
Available type is defined on thevcltypesand type name in each VCL
Type when it is interpreted in the C programis mapped.
In addition, this generate.py the thing you want to generate a file of the street name,
it generates the following files.
/ libvcl / vcc_token_defs.h // vcl_returns.h // vcl.h // vrt_obj.h / lib / libvcl / vcc_obj.c / lib / libvcl / vcc_fixed_token.c // vrt_stv_var.h / lib
/includeincludeincludeinclude


Lib


/libvcl/ vcc_obj.c
in the list of variables available in the VCL that is generated from generate.py,it is defined as follows.
{"bereq.between_bytes_timeout",, 27,DURATION,	Length/ / variable name  type name, the variable name
    "VRT_r_bereq_between_bytes_timeout (sp)",		when reading / / variable function name
    VCL_MET_MISS,|VCL_MET_PASS			Action readthe variable / /
    writing,"(sp, VRT_l_bereq_between_bytes_timeout"		at the time of  the variable / / function name
    VCL_MET_MISS,|VCL_MET_PASS			action  writethe / /
    0variable,},


Whenfunction name at the time of reading the variable / write to use the variable of the corresponding inline C. and is a function name to use
but it does not apply in this case the type of a variable is the HEADER,"req.http."
 HEADER{,9,
    "VRT_r_req_http_ (sp)",
    VCL_MET_RECV. VCL_MET_PIPE | VCL_MET_PASS | VCL_MET_HASH |
     | |  |  ||||| VCL_MET_MISS | VCL_MET_HIT | VCL_MET_FETCH | VCL_MET_DELIVER |
     |VCL_MET_ERROR,(sp,",VCL_MET_ERROR,
    "VRT_l_req_http_
    VCL_MET_RECVVCL_MET_PIPEVCL_MET_PASSVCL_MET_HASH
     VCL_MET_MISS  VCL_MET_HITVCL_MET_FETCHVCL_MET_DELIVER
     
    fact, "HDR_REQ",},


When using  req.http field name in the header and so
specifyto thereq.http.host.Function to be used in this case is not defined in the individual VRT_SetHdr and VRT_GetHdr. This function in common and so on all req.http ·
isusedbereq.http.There is a need to specify which one to read and write any header for that.
HDR_REQ that are in bold in the above hit it, I specify it arguments.
I more on that later.
/bin / varnishd / mgt_param.c
There is not much to do with the relationship line C inaccurate, we describe because it is one of a very important file.
This file contains a description and default value, maximum and minimum value of the startup parameters of Varnish.
Basically, it is may be carried out "param.show-l" by connecting to the management console If you want to know the list of parameters. But useless for this file
of startup parameters by when the version is raised, to the diff this
isused to examine the changefile.
The change of variable, you will know that generate.py also diff for the same reason.

/bin / varnishd / cache_center.c
After the start ofsession, a series of flow until the response has been described.
If you look at this file, movement of Varnish most can understand.
toa very conscious when dealing with simple inlineYou do not need C,but it is a file that can not be avoided in order to know more deeply Varnish.
For example vcl_hash or will be called at any time? Fetch to the back-end at any time? Such treatment has gathered all.
Please refer to the figure below.
At a high level, as a starting point CNT_Session, we will process it will call the steps together in the feature when Varnish to process the request.
For example, you follow a path similar to the following to end up in vcl_recv to be processed first thing in the VCL.
1. CNT_Session
2. cnt_wait
3. cnt_start
4. cnt_recv
     1.VCL_recv_method
Of particular importance  of each action, such as VCL and cnt_fetch cnt_recv is
isfunctioncalled.For example, let's look at the cnt_fetch.
int cnt_fetch
static(struct sess sp)
{/
	* snip  http_Setupberesp,/ *
	* wrk->  sp-> wrk-> (sp);

	(sp->ws);i = FetchHdr
	/snip * /
	if (i ==  backend_retry(sp);}(i) {/
		+ {sp-> 503;}
		1)  FetchHdr =sp->=
	

	iif
		{VSC_C_main->+;=handlingVCL_RET_ERROR;
		err_code
	else
		* snip * /
		VCL_fetch_method (

		(sp);switch{case(sp->NULL)sp-> sp->(0);(sp->
		VCL_RET_HIT_FOR_PASS:case
			if  objcore  objcore->==
				! =flags |OC_F_PASS;STP_FETCHBODY;
			sp->step
			handling)return
		VCL_RET_DELIVER:
			AssertObjCorePassOrBusyobjcore);STP_FETCHBODY;(0);break;}
			sp-> step =
			return
		default:
			
		
		/ * snip *
	/}

	/ * Koryaku *
For example/,is FetchHdr you are getting the header from the back end, but it fails to take I have retry only once case.
If the retry also fails, I will return the VCL_RET_ERROR as 503 status.
This is the same value as that of the the (error) return within a VCL.
It may be some person who noticed here, you can see that the movement is different if you can not connect to the server itself and the server returns a 503 explicitly.
vcl_fetch is not called if you can not connect to the server for call function of vcl_fetch, VCL_fetch_method is not only called when a successful acquisition of the header.
Reading cache_center.c to know the fine movement in this way is required.

if you go chasing the process,the action of each VCL isas
You think that it is easy to follow orand see the before and aftercalledVCL_recv_method.

This file please watch on more than inlining C.
It does not necessarily in-line C course.immediatelyif I look to the origin of these
I think even if the version is up, and you can grasp files.
The following describes the function and precautions minimum required in using the inline C actually.

Ways to perform the operation in-line variable
----------------------------------------------

To read and write variables in VCL (such as req.url) in ainline CC,it is necessary to devise a little bit.
For each variable, getter / setter are prepared, make the acquisition and set of values ​​using the function. I will explain their own way.
wayto read to each
I'm writing to vcc_obj.c you commentary by reading the source in thebasicallyvariable,butall
you rememberis hard. However, I will explain because there is regularity.
readingexcept HEADER型
variable name		beresp.backend.ip
C function name	berespVRT_r___backendipC;(sp).
Use the all function If you are loading a variable of VCL in-line
It is read-function name and replaced with "_" and "." To put the head of the variable name of the VCL "VRT_r_". In addition, sp of the first argument will be explained later, but please specify as it is sp, including the functions that appear in the future.

The return value is different depending on the type of each variable. Here is the list.







I will discuss each person.

BACKEND / struct director *
The type that contains the information ofback end.
However, you need to include the various headers to access members of this structure. It seems that generally used for retrieving the string in line C, which back-end has been selected for this purpose.

■I want to get the name of the back-end is set to req.backend.
const char * (sp,(sp))c =VRT_r_req_backendin;

typeBOOL / unsigned
The authenticity is VRT_backend_string.

DURATION / double
The type that contains a floating-point typetime.
Unit of storage is in seconds. Let's look at beresp.ttl as an example.

vcl_fetch  beresp.ttl{char"beresp.ttl
    sub{set= [64];=%(sp));str);}
    CC}
        60m;  64,
        snprintf    .3 f", VRT_r_beresp_ttl (LOG_INFO,
        str(str,syslog
    

ifyou have
beresp.ttl = 3600.000

You can get the output andsaid.


typeINT / int
The integer is located.

IPIP / struct sockaddr_storage *
The type that contains the address.
needto include the various headers You can access the members as well as the type
You BACKEND.commonto get a textual IP address in the line for the
I is probably C.

■getthe IP address that is set to
(sp,(sp))const char * ip = VRT_IP_stringVRT_r_client_ipclient.ip;

STRING / const char *
I contains thestring.

TIME / double
I am storing thetime.
It is a double, but for the following operation so time_t is possible in practice.
I saw to try by the now variable.

C
    {charstr (sp);t); 64,+1900);
    time_t  VRT_r_now =(&(str,=%
    [64];t struct tm * localtime ptime->
    = (time_t)ptimesnprintf  "year  d",  tm_year
    (LOG_INFO, str)
a}C;
ifyou have
year = 2011

You can get the output andsyslog.
The function called VRT_time_string If you want to get the string of an easier time are available.


    {((sp))(sp,LOG_INFO,VRT_r_nowVRT_time_string)
C;syslog}C.
ifwith a
2011 16:37:21 GMTSun, 11 Dec
It is output The format is "Y% T GMT% a,% d% b%".

The type list of variables that have more than utilized in VCL.

In addition, it will introduce in the list because there is a function to convert a string from each type than those listed in the text.

readof HEADER
variable name		resp.http.Expires
C function name	VRT_GetHdrHDR_RESP,(Sp,"\010Expires:")Kata;
since the number of elements is variable, HEADER type, such as type INT in the past for each element of each as, a fixed function does not exist. I will use the VRT_GetHdr all.
Is specified by the constant you want to see where the header in the second argument. The following is a list.


I specify the field name in the third argument. How to specify in this case care must be taken.
	Field Length(1byte) + Field Name(include : char)


For example, if you specify if you want to access to req.http.X is as follows.
(Sp,VRT_GetHdr;andHDR_REQ,"\002X:")
field name that you want to access is a single letter "X", but:real for is added
It is important to note though it is two characters"".
wayto write to each
It is a feeling similar to read in thebasicallyvariable,but you need to pay attention to the handling of string.
The type TIME and IP does not exist writable variable.
writingwith the exception of the HEADER · STRING Type
VCLbereq.connect_timeout		timeout;; set= 1m
C function name	bereqVRT_l___connect(Sp,60)
Function name starts with "VRT_l_", as well as the reading of the variable name "." It becomes a thing that bound by the "_". Of course it varies depending on the type of the variable part of the second argument are trying to operate.
I will explain each.
BACKEND / struct director *
You can specify theback end. It's good if you can specify the "client" in the string, but can not be that way. I will specify the following.

■definitionback-end
backend client{host =  Port = "81"}.

req.backendspecify the client to■
(sp, VGCDIR VRT_l_req_backendmacro;(_client))

VGCDIR is a "192.168.1.199";..;Be specified as "_client" it with a "_" If you have to "client" back-end name.

BOOL / unsigned
I specify theboolean value. It may be a matter of taste, butWhen the VCL to
it has been specified as follows:compile.
■■true
(0 (sp, VRT_l_req_esi; == (0==0))VRT_l_req_esi;

false
(sp, 1))

DURATION / double
You can specify thetime.
It is all in seconds.
INT / int
You can specify theinteger.

writingtype
VCLresp.response		set= "A" + "B"STRING;
C function name	VRT_l_vrt_magic_string_end)resp_response"A", "B",
			(sp,arguments;
It has become a variable length and the second and subsequent , they are combined in order if you specify more than one string.alsoalways thevrt_magic_string_endIspecifies thelast.Do not forget absolute behavior things get weird on you are not going to error to forget.
writingof HEADER型
VCLresp.http.X		VRT_SetHdr; set= "A" + "B"
C function name	("\HDR_RESP,,sp,002X:" "A", "B",
			vrt_magic_string_end);
until the third argument the same as when reading, the rest is similar to the way of writing of type STRING. String you specify more than one are combined.at thevrt_magic_string_endPlease specify theend.
In addition, you specify the following: If you want to delete the field itself
VCL		VRT_SetHdr;remove
C function
	Until 3.0.3 VRT_SetHdr(sp,HDR_RESP,”\002X:”,0);
	Until 3.0.4 VRT_SetHdr(sp,HDR_RESP,”\002X:”,vrt_magic_string_unset);
Third argument varies depending on the different versions.
There even to such a change in the change of revision Varnish.
Let's put out the code in the first-C If you suddenly stop working.

for struct sess *
The first argument of the function for reading and writing variablesp,has been designated the "sp" by all means.
This variable holds the state of the session.
For example, a variety of information such as the location of the object method of VCL currently running (such as fetch) is stored.
If you hang in there for that, and access to the Body section of the object,
an operation that can not be Normal is possible. However, you should do in VMOD If you are for the operation and include the header is very complicated.
Definition is located in the / bin / varnishd / cache.h.

Using built-in functions
------------------------

Built-in functions such a variety of hash_data and ban exists in the VCLfunctions.
I'll show you how when you call in-line and C listed below.
ban.
I will add to Ban list a regular expression that is specified

VCLreq.urlreq.url);		ban  req.http.host + ==" +
			("req.http.host ==" +"&&
Inline "req.http.host	VRT_ban_string(sp,(sp, VRT_WrkString
			C =  005host ","req.url",vrt_magic_string_end));
			VRT_GetHdr, (sp),
			sp,&&==
			"(\ VRT_r_req_url
			=HDR_REQ,:")

ban will be VRT_ban_string, but you should note one point.thatthis function itself
It is doesnot allow more than one text. There is a need to assemble the text in advance for that.
It is VRT_WrkString is to use at that time. This function assembly operations (as explained below) the text by using the workspace. Like when you were dealing with more than one text until now, this also specifies the vrt_magic_string_end at the end always.
ban_url.
I will add to Ban list the URL that is specified

ban_url		VCL(req.url);
Inline C	VRT_ban(sp, "req.url", "~",
 			VRT_r_req_url 0);(sp),

argument of this function is a variable length, but it is as real as long as the following to see the code.

VRT_ban.(sp, "evaluation", "operator", "evaluation", 0)also;
The last argument of this function be careful so 0 instead vrt_magic_string_end
that call
which is called the sub-functionsuser-defined

VCL		(1);;call
Inline C	if  inlineTest(VGC_function_(sp))
			return to inlineTest

function defined is the VGC_function_ # # define name # #.
hash_data
I will add to the definition of the hash to be used to identify and storeobject.

hash_data "_pc");"_pc",		VCL+ (sp),
Inline C	(req.url (sp,VRT_r_req_url VRT_hashdata;
			vrt_magic_string_end)

function this also because it is a variable number of arguments, I specify the vrt_magic_string_end at the end.
panic
with the message that isspecified, kill the child of the current process.

VCL		CVRT_panic;;panic ("ng" +
Inline req.url)	(sp,  vrt_magic_string_end)),vrt_magic_string_end
				(VRT_WrkString)(Sp,
				"ng",VRT_r_req_url
				(sp),
			

argument of this function is also variable length. But arguments that should be used in the internal structures fact because only one eye of variable length part, join is necessary in VRT_WrkString.
requiringVRT_WrkString · VRT_panic both vrt_magic_string_end
Please note that course.
purge.
I immediately removes the selected object current

VCL		VRT_purge;purge.
line C	(sp, 0,0)

return
I will return thefunction;

VCL		VRT_done;;return (deliver)
Inline C	(Sp, VCL_RET_DELIVER)

and deliver that you specify in the "VCL_RET_" in the Prefix after all capital
argumentwith theletters.
synthetic vcl_error.
Create a response body to be used in such

VCL		arguments;synthetic  +"url",
inline C	"url"(sp, 0,  VRT_r_req_url VRT_synth_page.
			req.url;(sp), vrt_magic_string_end)

I specify the vrt_magic_string_end to end this function because a variable number of
The function of VCL is valid only in vcl_error, but I am sure that if vcl_deliver in-line C even works.
rollback
I will initialize. * variablereq.

VCL		rollback;
line C	(sp)VRT_Rollback;

error
with the specified message andstatus code, a transition is made ​​to vcl_error.

VCL		this;error (404,
Inline C	"NotFound.");VRT_error (sp, 404, "NotFound.")

Because it does not allow more text, use the VRT_WrkString If you want to assemble a string of more than one function .

Is over.
Omit for that use in-line C is virtually difficult (regsub, regsuball) regular expressions. I have been described in parts of the VMOD.

Using external shared libraries in-line
---------------------------------------

If you want to use shared libraries, such as libmemcached libxml2 orC,you should use the VMOD originally. However, if you want to use inline C absolutely,
it becomes possible to call the shared library by changing the cc_command startup parameter.
cc_command is the command to be used when the Varnish to compile the VCL. I will explain to the libmemcached example this time.

First, I'll make sure the current parameters.
@ localhost ~] # varnishadm param.show cc_command cc_commandgnu99-O2-g-pipe-Wall-Wp,-D_FORTIFY_SOURCE
[Root"execgcc-std =  = 2-fexceptions-fstack-protector - param = ssp-buffer-size = 4-m64-mtune = generic-pthread-fpic-shared-Wl,-x-oparameters%o% s"~
~ Koryaku

Please be sure to check for default is different depending on the environment.
When you are confirmedstartup parametersto-lmemcachedto add.
=  $ {VARNISH_LISTEN_PORT}  testsv  $   $  $   $   $
DAEMON_OPTS"-a\-i
             $ {VARNISH_LISTEN_ADDRESS}:\-f{VARNISH_VCL_CONF}
             \-T{VARNISH_ADMIN_LISTEN_ADDRESS}:{VARNISH_ADMIN_LISTEN_PORT}
             \-t{VARNISH_TTL}
             \-w{VARNISH_MIN_THREADS $ {VARNISH_MAX_THREADS}, $ {VARNISH_THREAD_TIMEOUT}cc_commandgnu99-O2-g-pipe-Wall-Wp,-D_FORTIFY_SOURCE
             varnish gcc-std2-fexceptions-fstack-
},\-u\-p==='execvarnish-g   protector - =  = 4-m64-mtune = paramssp-buffer-size generic-pthread-fpic-shared-Wl,-x-lmemcached-o%o%'for \
"contains
spacess,such as"' " Do not forget to enclose.
This time,code to be stored in memcache value as the treatment req.http.X-mcv as a key string that is stored in req.http.X-mck If you call the mcSet of
you will writesub-function.

<libmemcached/memcached.h>mctest memcached_stmemcached_server_st
{#<stdlib.h> # include# include
include<stdio.h>

void(char  k, char * v)**
        C*{structmmc  struct= NULL
        = NULL;servers memcached_returnmemcached_creatememcached_server_list_appendrc);memcached_server_pushservers);memcached_server_list_free memcached_set
        ;rc; rcrc
        mmc (NULL);=(servers,=(mmc, (servers);=(mmc,(
         = servers "localhost", 11211, &
        
        
        k,strlen v, strlen  600,  memcached_free mcSet(req.http.X-mckreq.http.X-mcv)
        k),(v),0);(mmc);}}


C{C

sub{if
	&&
		
			{char* key = VRT_GetHdr (sp, HDR_REQ, "\  mctest  req.http.
			VRT_GetHdr  HDR_REQ, "\ char * 006X-mcv:");value);}
			=(sp,006X-mck:");value(key,
		C}
	
	remove  req.http.X-mcv;}vcl_recvreq.http.X-mckreq.xid";req.http.X-mcvreq.xid;mcSet;
	remove

X-mck;sub{set
	"Last:  set=
	=
	call
~ ~

I tried to get the value to connect to memcache a telnet actuallyKoryaku.
[Root @   # telnet localhost 11211localhost'^]'
Trying 127.0.0.1 ...
.localhostConnected to
libmemcached-1.0.2]Escape character is req.xid:.
get Last:0
10 Req.xid VALUE Last
1938831702
END
actualI can confirm that the value is set to.
Is necessary to be careful when using shared libraries in-line C, it is that there is a need to specify the cc_command even when debugging.
If you do not specify, you can not perform undefined symbol comes out naturally.

Basic Required Knowledge When Using VMODs
=============================================

Trouble like the following will come out when you try to write code in a large C-lineVMOD.
-Troubledifficult to line C are mixed in the
andirregular or use HEADER variable to passread,variable
variety will come out alsootherVCL.
I think It depends on the how to write code, and difficult to reuse some code written in inline C.
It is VMOD there comes out.
VMOD is easy to use and easy to deploy as a module of Nginx and Apache.
Let's grab the sense to try to put the first VMOD that have been distributed.

(vmod_example) Try using the VMOD
---------------------------------

Let's use it to download the official vmod_example that Varnish is distributed firstoutside.
HelloWorld
This module is simple enough to output the  https://github.com/varnish/libvmod-example.
It was introduced in the following manner: In my.
wget http://repo.varnish-cache.org/source/varnish-3.0.2.tar.gz [root @ localhost example] #varnish-3.0.2.tar.gz[
@ localhost example] #tar zxf
[Root @ localhost varnish-3.0.2] [root@ localhost varnish-3.0.2] # @ localhost varnish-3.0.2] # cd
root @ localhost example] #varnish-3.0.2 [root#./ configure [root
make
cd ..https://github.com/varnish/libvmod-example.gitlibvmod-examplelibvmod-example]
git clone[root @ localhost example] #[root @ localhost
[root @ localhost example] #cd /
/#.autogen  shlibvmod-example] #.example/varnish-3.0.2libvmod-example]libvmod-example]
. / configure VARNISHSRC = ~ /[root @ localhost  #[root @ localhost  #		· · · (1)
[root @ localhost make
make check	· · · (2)
[root @ localhost libvmod-example] # make install	· · · (3)

You must also specify the source directory of the configure Varnish first place that need to beNote.
When you are satisfied with the only source simply, there is no problem if you specify the location to install the varnish-debuginfo. However, since varnishtest being compiled is required, I have make the source of the varnish of the same version.
is not required to make install.
I also will make check in tests make later.
When you do make install, it is copied to the installation location for VMOD of default. In my it was / usr/lib64/varnish/vmods /.

We'll use VCL immediately from the next.
I write a VCL as follows.
example;;vcl_deliverresp.http.hello
importsub{set
	= example.hello
("World")}.
in response headers and try to request in this state
Hello, Worldgranted:hello
is

to try to add a function to
---------------------------

We will look at the structure of the previous vmod_examplevmod.The following is the file tree.
.
─ autogen.sh ├ ─ ─├ ─ ─├ ─ ── ─├ ─ ─├ ─ ── ─├ ─ ─├ ─
├ configure.ac
LICENSE
m4
─│ PLACEHOLDER└
Makefile.amMakefile.am
README.rst
└src
    
    ─tests
    ​​from,│  ── ─└ ─ ─
    ─├
    └

10 filestest01.vtcvmod_example.cvmod_example.vcc 3 directories

It's made 1also is good, but it will continue to edit based on vmod_example because it is time.
File you need to edit whenever that is the following.
vmod_example.c src /
src /

We'll add one simple function firstvmod_example.vcc.
The name is len, I will return the length of the string.
I will fix as follows vmod_example.vcc first.
~ snip ~
STRING hello (STRING) Function
FunctionINT len(STRING).

I will fix as follows vmod_example.cthen
~ snip vmod_
int ~(p))(structsess * sp, const char *len.
{(strlen
        once;  p)
return}
Let's use it to make at is following
state;("Hello World!!") Set resp.http.len = example.len
in response headers and try to request this
13granted:len
is VCL.
I think it was found that you can add a function very easily.
It will explain what you actually use more of the following.

(vmod.vcc)vmod_example.vcc
--------------------------

I define an interface for call from VCL VCL and the compilerVMOD There are three elements in the
Module	[module name]			indicates the name space of the VMODfollowing.
Init[function name]				This is the initialization functionofVMOD.
Function [Return Type [Function Name](the type of the	is a function called from VCLargument).
The first is treated as a comment if the "#". Please note that it will be error or "/ /" and "/ * ~ * /".
I will explain each.
Module [module name]
Define theModule name. This name must not overlap with other modules.
I is defined as follows.
whenModule example
Init [function name]
This is the initialization function of VMOD called  theVCL is loaded.
It is used to initialize the table or the like that need to be initialized in advance.
I is defined as follows.
Initinit_function
Does not have a release process for the Init,but this can be solved by taking advantage of the active work space private pointer VMOD, which will be described later.
Function [Return Type [Function Name](the type of the
is a function that is called from VCLargument).Each type is the type of a VCL rather than the type of the C language.
I is defined as follows. Function name is allowed only lowercase alphanumeric characters.
■There return
Function STRING hogehoge (INT, STRING)

■no return value
(INT, STRING)Function VOID hogehoge
I will later typeof variablevalue.

vmod_example.c (vmod.c)
-----------------------

The codeof VMOD real.
You need to include the header of the following means.
#include
The name of the function with the vmod_ to head with the name that you defined in the vcc also"vcc_if.h".
■nameat the
hello

■name of theC
vmod_hello
as well as functions that are covered in-line C alsoVCC,the first argument will always sp.
int(structsess  sp,* {(strlen(p))*const char
        p)vmod_len.
return}
It depends on variables that receive the second and subsequentarguments;
I will be discussed later init_function.

typeof variables available in VMOD
----------------------------------

Types can be used in the  VMODis almost the same as the VCL. But you or there is a special type Ri was part deprecated.
Return value is of a △ is, it is because the variables that you can write does not exist, useless did not think so much. Also were deprecated is what is listed in the official documentation.
The commentary to make a simple function whose return value argument, each variable.
BACKEND
I have to store the information ofbackend. You can specify an argument, the return value both.
■tbackend■vmod_tbackend■req.backendexample.tbackendvcc
Function BACKEND(BACKEND)(structp)(req.backend);

c
struct director * sess * sp, struct director *
	{return
p;}

VCL
set=
member of the director if There is a need to include header the following if you want to access.
# varnishd / cache.h"include "bin / varnishd / cache_backend.h"
include "bin /#
Return it, otherwise the back end that is currently selected if backend specified asexample is normal and returns.
■gethealthydirector■vmod_gethealthydirector■vcc
Function BACKEND(BACKEND)(structp)(VDI_Healthy(p, sp))

c
struct  **struct director *director;}
sesssp, {if sp->
	
		return
	p;}
	director{return


VCL
set req.backend = example.gethealthydirector (client_2);
VDI_Healthy will return the state of the back end.
There is a need to include header below to use.
#typeinclude "bin / varnishd / cache.h"
BOOL
The authenticity is on.
■tbool■vmod_tboolvcc
Function BOOL(BOOL)(structp)

c
unsigned sess * sp, unsigned {return
	
p;}

■VCL
time;set req.esi = example.tbool (req.esi)

DURARATION
is stored in a floating-point typeThe type you have.
■tduration■vmod_tdurationvcc
Function DURATION(DURATION)(structp)

c
double sess * sp, double {return
	
p;}

■VCL
stored;set beresp.ttl = example.tduration
typeINT
The integer is (10m).
■■vmod_tintvcc
Function INT tint (structp)

c
(INT)int sess * sp, int {return
	
p;}

■VCL
address;set beresp.status = example.tint (200)
IPIP
The type that is stored the .
■■vmod_tipvcc
Function INT tip (structp)(p->AF_INET)(p->AF_INET6)

c
(IP)int sess * sp, struct sockaddr_storage * {if {return{
	4;} if  ss_family ==
	ss_family == return resp.http.iptypeexample.tip
	return 0;}
6;}

■VCL
set=(client.ip);
You can access the elements of sockeaddr_storage, you must include the following header.
#typeinclude "sys / socket.h"
STRING
The string is stored.
■■vmod_tstring■resp.http.strexample.tstringvcc
Function STRING tstring (structp)("abc");

c
(STRING)const char * sess * sp, const char *
	{return
p;}

VCL
set=
in VCL I will complement the case VRT_WrkString binding of string is needed.
STRING_LIST
Available only inargument, a string of more than one is a list of available types.
■tstring_list■vmod_tstring_listvcc
Function STRING(STRING_LIST)(struct...)(ap, p);(sp-

c
const  sess *  const char *   char *
	char *{va_listap;b; b
	sp,p,va_start
	= VRT_String  > wrk-> ws, NULL, p, ap);
	va_end (b);}("abc", "aaa")
	here;return


■VCL
(ap);set resp.http.str = example.tstring_list
to use VRT_String have by combining the character by using the
isa function that is summarized in oneworkspace.You need to include the following to use.
#include "bin / varnishd / cache.h"
I will be discussed laterworkspace.
HEADER
The type that contains theheader.
■theader■vmod_theadergethdr_evcc
Function STRING(HEADER)(structp)(e)("req");

c
const char * sess * sp, enum const char *   {case
	e,{switch
		HDR_REQ:case
			return
			break;
		HDR_RESP:
			return  return ("bereq"); return ("beresp");  return "";
			("resp");break;break;break;break;}
		case HDR_OBJ:case case
			return ("obj");
			
		HDR_BEREQ:
			
			
		HDR_BERESP:
			
			
	
	
e";}

■VCL
set resp.http.test = example.theader
Where the header is included in the "enum gethdr_e (req.http.x).
The field name is "const char * p": contains in with "".
REAL
The type that contains thefloating point.
DURARATION while representing the time, REAL represents the floating-point number simply.
■treal■vmod_trealvcc
Function REAL(REAL)(structp);

c
double sess * sp, double {return
	p
+0.1}

■VCL
(example.treal (0.5)> 0.5)if
TIME
This is the type that is storedistime.
■■vmod_ttimevcc
Function TIME ttime (structp)

c
(TIME)double sess * sp, double {return
	
p;}

■VCL
example;(now)set resp.http.time = example.ttime
is added to the time specified as an I'll try to make a function.
■■vmod_timeoffsetvcc
Function TIME timeoffset  DURATION, (structsp,time,os,rev)(rev)

c
(TIME,BOOL)double sess   double  double  unsigned   {os *timeos;}
	* {if=
	return+
-1;}

■resp.http.timeexample.timeoffset;VCL
(now, 1h, false)set=
third argument becomes true, I will minus against time.
VOID.
The type that you specify if there is no return value
■tvoid■vmod_tvoidvcc
Function VOID()(structsp)

c
void sess * {return;}
	


■VCL
()example.tvoid.
PRIV_VCL
is a special type that validVMOD within, a privatepointer;
thatare described
PRIV_CALL
This is a special type that specifies the valid private pointer in the call function ofVMOD later.
Later.

Using the Varnish session workspace
-----------------------------------

TheVarnishworkspace,I have a work space in each session.in the main
Return value is a stringVMOD,I use it when you need to allocate memory.
tothe memory leak if you allocate memory from here, it will give you control Varnish
Do not haveworry aboutside.64KB has been secured default, I can change the size of sess_workspace startup parameters.
It seems a good size when I hear and 64KB. examplea
Butlet's open those you ensure if unnecessary because it is also used in otherraw data whenclientthat requests also, or are stored.
State of the area of the workspace there are three.


The area, you need to commit or roll back the area always when finished using time. You can make a temporary area for up to one, again without both
It is an error to start the transaction.
It's time to actually use.
function you want to use the header that must be include are the following
#include "bin / varnishd /
Beginning of a transaction(Free space reservation of the workspace)
■function
	(struct ws * ws, unsigned bytes)unsigned WS_Reserve;
■argument
	struct ws * ws		specifyensureworkspace,
	unsigned bytes		allremaining specifies the byte you want to  if you specify 0
■value return
	the number of bytes was able to secure

Commit rollback processing area(To determine the area of use of the workspace)
■function
	(struct ws * ws, unsigned bytes)void WS_Release;

■argument
	struct ws * ws		specifiedcommitworkspace,
	unsigned bytes		numberof bytes

I will write code to ensure 10 bytes as an example.
If you are unable to 10 bytes secured, it returns NULL by opening.

	u = WS_Reserve(sp->wrk->ws, 0);
	if(u<10){
	  WS_Release(sp->wrk->ws,0); //Exit processing can secure area because 10 bytes or less
	  return NULL;
	}
	char * str = (char*)sp->wrk->ws->f; //Specifies a pointer of free space
	...
	processing
	...
	WS_Release(sp->wrk->ws,10); //10 bytes to commit


how to usethe private
---------------------

session workspace ofjustpointer,will be cleared each time a session is started. only once or decompilation of the regular expression, the processing of the high
For example,what should I do when to callcost,I want to turn to use after that?
I have what's called private pointer in Varnish.
This is a mechanism that can hold such as a table that is set in a different session.

I will two types exist in the private pointer.
It is priv_vcl valid VMOD within. Please see the illustration below.
Private pointer is assigned to VMOD for each.
It is also possible that you reference in the fetch value set in the recv for that.

The other is priv_call. Please see the illustration below.
This is to assign a private pointer to call each function.
Even in the same function, please keep in mind that a separate pointer is assigned.
Value that you set is visible in the next session.
The following describes the code when you put it into operation.
needofto be
A large number of threads will move at the same time the Varnishthread-safe.There is no problem even without being aware of that because it is reserved for each thread, and running in a multi-threaded, especially for session work space.
However, it is different if you use a private pointer. Please see the illustration below.
whatif you write a program to increment the counter common to every access
But if?The following phenomena will occur.
1. Thread from A private"1"get the
pointer2. Thread Bfrom the private"2""1"getand
pointer3. Thread A private pointer to   "2"writeand
to the private pointer 4. Thread B   write.
contents of the pointeris written to twice"3"not"2"will be
If you use a private pointer,mustbe aware that it is thread-safe for
you that.
There are two ways in order to be thread-safe.
lock.
	multiple threads and do the resources of a particular
	onefor (= critical section) process leading to collapse
	How it Works onlythread to be able to be processed

lock-free
	multiple threads even after the operation of theresources
	The mechanism that allows it to avoid collapseidentified.
youto maintain the private pointer what you have access to files on the
It is recommended a lock if  wantlocal.
■ static variable declared
pthread_mutex_t tmutex	  static= PTHREAD_MUTEX_INITIALIZER;

■ locking
(pthread_mutex_lock (& AZ
~ critical section ~
function;(pthread_mutex_unlock (& tmutex))AZ;tmutex))
AZ is defined by the macro of Varnish to an error when a non-zero It is below.
# Define AZ ((foo)0);}		(foo)do {assert==  while

(but 0),that you do not lock as much as possible in the case of simple increment is desirable. A program that runs in a thread more than a few hundred,critical sections in many
you do not want to becases.There is a possibility that a number of "town" occurs if the situation is lots of threads compete for resources even one over processing in an instant.
Due to space limitations, it does not describe a specific method in this book, butforthe following documentation  very
it is recommended reading isinformative.
(@  http://www.slideboom.com/presentations/460931/Lock-Free festival of winter
Lock-Free Festival of _safekumagi's)Winter
Due to space limitations,especially inthe example on the following pages Thethread-safe awareness does not have.

PRIV_VCL
InVMOD is a private pointer common
entire vcctpriv_vcl
■Function INT(PRIV_VCL)vmod_tpriv_vcl vmod_privpriv)(priv->NULL)

■c
int(structsess  sp, struct*  *priv{priv-
	*i;
	{intif ==
		malloc(sizeof = (int  priv;=  = = (int
		> priv   * ipriv->{i*) priv->*
		=i*)0;
		(int));priv->freefree;}
	else priv;}
		
	
	i * resp.http.test = example.tpriv_vcl
	i*return
i;}

■VCL
=+1;set();
is PRIV_VCL, you do not need to be specified in a separate argument when calling from VCL. Varnish complements when calling VMOD function.
There is a need to include the following header to be able to use it.
#include"vrt.h" stuct vmod_priv
Structure around is the following.
vmod_priv_free_fstructstruct
typedef void(void
{function
	void			*		/ / private pointer pointer
	vmod_priv;;vmod_priv_free_fvmod_priv	priv;;* *)		to be called when the / / release
free};

is necessary to be careful here,to call when you releaseisto specifyIt the function.
If and free priv is defined in the VCL at the end, Varnish the functions
willopen by callingdefined.
I specifies the () free to release the memory in the example.staticif you want to implement your
Please makefunctionown.
PRIV_CALL
It is a private pointer that can be used in everycall.
In the same definition as PRIV_VCL, the change basically only typed argument vcc.
vcctpriv_call■vmod_tpriv_callvmod_priv
■Function INT(PRIV_CALL)(struct(priv->(sizeof(int)priv)NULL)

c
int sess  sp, struct*  *priv{priv->priv
	*i;
	{intif ==
		= malloc );*)priv;0;free;}*)priv;}+1;
		* i =priv->={i= (int  priv->  * i = * i*
		i
		=priv->free
	else
		(int
	
	
	return i;
()}

■VCL
set resp.http.test =
init_function;
It is init_function of initialization function of vmod who had just skipexample.tpriv_call.
This also includes PRIV_VCL.
vmod_priv * priv, const struct VCL_conf *  int init_function
	(structconf) {return
(0);}
use of PRIV_VCL excluded because it does not like. In addition,set of VCL
there was a store (such as a pointer to the action of VCL and file name)itself* conf.
There is a need to include the following header To take advantage of this.
#include "vcl.h"


to use external shared libraries inVMOD
---------------------------------------

The use of shared libraries external VMODis very easy.
We'll use the libmemcached as you would with a inline C.

I have to change the / src / Makefile.am first.
libvmod_example_la_LDFLAGS
 =-module-export-dynamic-avoid-version-lmemcached-lmemcached 
I will add  to LDFLAGS.
The following describes and c vcc.
vccmcset■<libmemcached/memcached.h>vmod_mcset
■Function VOID STRING)(structsp,k,

c
<stdlib.h> # include# include
# include<stdio.h>

(STRING,void sess *  const char *  const char   memcached_st *memcached_server_st *memcached_returnmemcached_create memcached_server_list_appendrc);memcached_server_push
        *{struct struct= NULL; mmc =(NULL);==(mmc,
        NULL;serversservers(servers,servers
        rc; rc

        
                = "localhost", 11211,
                                v) &
        mmc  memcached_server_list_free memcached_set(k),(v), memcached_free example.mcsetreq.xid
        );(servers);(mmc,(mmc);}("Last:
                rc = k,    strlen
                        strlenv, 600,0);

        


■VCL
simple;req.xid),
You can see as compared to inline C, calls from the VCL's very ".
In the case of VMOD, do not need to change the cc_command of startup parameters such as set in-line C.
From this point, I would recommend VMOD When you use external libraries.

that use regular expressions in
-------------------------------

I wrote during the description of inline CVMOD,to be omitted for regular expression is difficult in nature.
As a reason, because Varnish performs first compilation of regular expressions, be confusing to imagine the regular expression of the original approximate said, "VGC_re_ [Numeric]" and its name. There is no storage method beyond the session in inline C further, as private pointer. We believe it inappropriate to use fact in order for that, there is no choice but to open immediately performed each time compiled to use a regular expression.
However, private pointer exist in VMOD. It is possible to turn use the compiled regular expressions for that. Is an example below.
vcc■regexfini
Function BOOL  STRING, regexregex;};(voidd)regex regex (
■c
regexstruct   * void *{struct*(struct*)d;
(PRIV_CALL,STRING){char voidstatic
	*pat;r =
	freer->  vmod_regexvmod_privpat,tg)regex;0;
	VRT_re_fini (structregex
regex);}
(r->unsigned sess  sp, struct* priv, const char *  const char *  {struct*
	pat);*int flag =
	if  priv == {regex(struct*)priv-> (!(regex->pat) {regexfini
		=priv;=(regex);
	{flagelse
		(priv->NULL) regex
		=if  strcmppat, 0)
			1;}
			(flag)=regex));=priv;=
		1;}}
	
	flagif (sizeof (struct*)  (
		priv  regex regexpriv->  regex->malloc
		{priv->(struct *)
		=mallocpat(char(strlenpat) +1);pat,pat);pat);regexfini;}regex);}
		strcpy (&regex-> regex,priv->(tg,regex->
		VRT_re_init
		(regex-> free =
	
	return VRT_re_match

■VCL
example.example;regex (req.http.regex, req.url)
compilation is open if during the same regular expression comes, regular expression different from the one you use something that is stored in a private pointer, stores came in the It is a thing to be done continue.
The function on regular expressions is as follows.
VRT_re_init ([pointer that contains the regular expression], [regular expression])
	that compiles the regular expression
([pointer to store the regular expression]) VRT_re_fini
	to release the compiled regular expressions
VRT_re_match([evaluation string], [regular expressionpointer])to store a
	being matched with theregular expression
(sp, [replacement flag], [evaluation string], VRT_regsubpointer to store the regular expression],thereplacement string])
	the replacement flag to be replaced in regular expression The first match,replacementall in the case of 1 for

How to debug a VMOD using varnishtest
-------------------------------------

there are several ways to do debuggingVMOD0.The best is to use the varnishtest.
Definition of vtc in varnishtest normal does not change, but you may not forget only one.
Perform the import of vmod course in the definition of the VCL, but you must specify the location for vmod doing the test.
I proceed as follows.
varnish v1-vcl + backend
	{importexample from
 		"$ {Vmod_topbuild} / src / .libs / libvmod_example.so";
	~ VCL snip
~}-start

alsothe vtc if I put in / src / tests /, even without adding to Makefile.am
youcan test thatespecially(if)like,which is based on vmod_example

News
====
We are planning that it produces a Varnish book early next yearPublishing Co. master from (http://tatsu-zine.com/). I think that is when you notice on Twitter and blog and also when it is close, but Thank you so packed with various things and what you have not written in the interest of time until now.

postscript!
-----------
The Nice to meet you lack how it started  It is Iwa-mei chan Iwa-mei marshmallow.
Following the summer Komi, I made ​​this Varnish. It is billed as inline C · VMOD this time, but I mean if used to like not afraid version up for the purpose of back in to. I am a difficult subject as you know, Varnish to conduct incompatible changes considerably, transition documents in that case also is being honest enhancement. But aboutit then · diff view the source
changes or you will knowspecific.I am happy if you can grasp the sense to read this book.
also(no calibration) timing you have finished writing for the time being this isandComiket 4 days
It waslast-minute schedulenot horriblycould dropwhat.Descriptions Hasho~tsu drinking tears for the lot, too there (like varnishtest) · · ·.I perform the calibration from now on,
I thinkwhether there is a point to this is hard to read maybe. Really sorry.
Then again if the opportunity arises!

Version
-----------
v5
	2013-06-30(JA)
	Follow Varnish verup(3.0.3 -> 3.0.4)
v4
	2012-06-01(JA)
	3rd argument description VRT_GetHdr/SetHdr
v3
	2012-02-15(JA)
	how to use SessionWS, I forgot to write a use sp->wrk->ws->f
v2
	2012-01-26(JA)
	fix rollback description
	fix some miss.
v1
	2011-12-31(JA)
	first version

Imprint
Cache inline-C/VMOD
Varnishguidebook
over over over over Issue Date
(First edition)2011-12-31xcir)
2012-01-26 (version 2)
issue over over over over
marshmallow char
over overissuer over over
Iwa-mei Chan (@
over over over over contacts
Varnish

overover Special Thanks (titles omitted) over over
dai_yamashita @
@W53SA
and
Software http://xcir.net/

