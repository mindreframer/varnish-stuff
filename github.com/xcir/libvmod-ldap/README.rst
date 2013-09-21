===================
vmod_ldap
===================

-------------------------------
LDAP module for Varnish
-------------------------------

:Author: Syohei Tanaka(@xcir)
:Date: 2012-10-23
:Version: 0.2
:Manual section: 3

SYNOPSIS
===========

import ldap;


DESCRIPTION
==============

simple authenticate
----------------------

        ::

                import ldap;
                
                sub vcl_error {
                  if (obj.status == 401) {
                    set obj.http.WWW-Authenticate = {"Basic realm="Authorization Required""};
                    synthetic {"Error 401 Unauthorized"};
                    return(deliver);
                  }
                }
                
                sub vcl_recv{
                
                if(req.url ~ "^/member/"){
                        if(!(req.http.Authorization && ldap.simple_auth(
                                true,
                                "cn=Manager,dc=ldap,dc=example,dc=com",
                                "password",
                                "ldap://192.168.1.1/ou=people,dc=ldap,dc=example,dc=com?uid?sub?(objectClass=*)",
                                ldap.get_basicuser(),
                                ldap.get_basicpass()
                        ))){
                                error 401;
                        }
                }

advanced authenticate
----------------------

        ::

                import ldap;

                sub vcl_deliver {
                  //close ldap
                  ldap.close();
                }
                sub vcl_error {
                  if (obj.status == 401) {
                    set obj.http.WWW-Authenticate = {"Basic realm="Authorization Required""};
                    synthetic {"Error 401 Unauthorized"};
                    return(deliver);
                  }
                }
                
                sub vcl_recv{
                
                  if(req.url ~ "^/member/"){
                        if(!(req.http.Authorization && ldap.open(
                          true,
                          "cn=Manager,dc=ldap,dc=example,dc=com",
                          "password",
                          "ldap://192.168.1.1/ou=people,dc=ldap,dc=example,dc=com?uid?sub?(objectClass=*)",
                          ldap.get_basicuser(),
                          ldap.get_basicpass()
                        ))){
                                error 401;
                        }
                        //compare group
                        if(!ldap.compare("cn=test,ou=people,dc=ldap,dc=example,dc=com","memberUid")){ldap.close();error 401;}
                        //compare user
                        if(!require_user("uid=hogehoge,ou=people,dc=ldap,dc=example,dc=com")){ldap.close();error 401;}
                        //authenticate user
                        if(!ldap.bind()){ldap.close();error 401;}
                        //close ldap
                        ldap.close();
                  }
                }


FUNCTIONS
============


get_basicuser
------------------

Prototype
        ::

                get_basicuser()
Return value
	STRING
Description
	get user name from Authorization header
Example
        ::

                ldap.get_basicuser();



get_basicpass
------------------

Prototype
        ::

                get_basicpass()
Return value
	STRING
Description
	get password from Authorization header
Example
        ::

                ldap.get_basicpass();


simple_auth
------------------

Prototype
        ::

                simple_auth(
                    BOOL   isV3,
                    STRING basedn,
                    STRING pasepw,
                    STRING searchdn,
                    STRING user,
                    STRING pass)
Return value
	BOOL
Description
	authenticate users
Example
        ::

                import ldap;
                
                sub vcl_recv{
                  if(req.url ~ "^/member/"){
                    if(!(req.http.Authorization && ldap.simple_auth(
                        true,
                        "cn=Manager,dc=ldap,dc=example,dc=com",
                        "password",
                        "ldap://192.168.1.1/ou=people,dc=ldap,dc=example,dc=com?uid?sub?(objectClass=*)",
                        ldap.get_basicuser(),
                        ldap.get_basicpass()
                    ))){
                        error 401;
                    }
                  }
                }

open
------------------

Prototype
        ::

                open(
                    BOOL   isV3,
                    STRING basedn,
                    STRING pasepw,
                    STRING searchdn,
                    STRING user,
                    STRING pass)
Return value
	BOOL
Description
	init ldap connection
Example
        ::

                import ldap;
                
                sub vcl_recv{
                  if(req.url ~ "^/member/"){
                    if(!(req.http.Authorization && ldap.simple_auth(
                        true,
                        "cn=Manager,dc=ldap,dc=example,dc=com",
                        "password",
                        "ldap://192.168.1.1/ou=people,dc=ldap,dc=example,dc=com?uid?sub?(objectClass=*)",
                        ldap.get_basicuser(),
                        ldap.get_basicpass()
                    ))){
                        error 401;
                    }
                  }
                }

close
------------------

Prototype
        ::

                close()
Return value
	VOID
Description
	close ldap connection
Example
        ::

                ldap.close();


get_dn
------------------

Prototype
        ::

                get_dn()
Return value
	STRING
Description
	get DN
Example
        ::

                ldap.get_dn();

bind
------------------

Prototype
        ::

                bind()
Return value
	BOOL
Description
	bind
Example
        ::

                if(!ldap.bind()) {error 401;}

require_user
------------------

Prototype
        ::

                require_user(STRING)
Return value
	BOOL
Description
	compare user
Example
        ::

                if(!ldap.require_user("uid=hogehoge,ou=people,dc=ldap,dc=example,dc=com")) {error 401;}

compare
------------------

Prototype
        ::

                compare(STRING, STRING)
Return value
	BOOL
Description
	compare
Example
        ::

                if(!ldap.compare("cn=test,ou=people,dc=ldap,dc=example,dc=com","memberUid")) {error 401;}

compare_dn
------------------

Prototype
        ::

                compare_dn(STRING, STRING)
Return value
	BOOL
Description
	compare
Example
        ::

                if(!ldap.compare_dn("cn=test,ou=people,dc=ldap,dc=example,dc=com","memberUid")) {error 401;}


compare_attribute
------------------

Prototype
        ::

                compare_attribute(STRING, STRING)
Return value
	BOOL
Description
	compare
Example
        ::

                if(!ldap.compare_attribute("test","initials")) {error 401;}

INSTALLATION
==================

Installation requires Varnish source tree.

Usage::

 ./autogen.sh
 ./configure VARNISHSRC=DIR [VMODDIR=DIR]

`VARNISHSRC` is the directory of the Varnish source tree for which to
compile your vmod. Both the `VARNISHSRC` and `VARNISHSRC/include`
will be added to the include search paths for your module.

Optionally you can also set the vmod install directory by adding
`VMODDIR=DIR` (defaults to the pkg-config discovered directory from your
Varnish installation).

Make targets:

* make - builds the vmod
* make install - installs your vmod in `VMODDIR`
* make check - runs the unit tests in ``src/tests/*.vtc``


HISTORY
===========

Version 0.2: Bugfix: sometimes segfault on x86_64.
Version 0.1: initial

COPYRIGHT
=============

This document is licensed under the same license as the
libvmod-rewrite project. See LICENSE for details.

* Copyright (c) 2012 Syohei Tanaka(@xcir)

File layout and configuration based on libvmod-example

* Copyright (c) 2011 Varnish Software AS

base64 based on libvmod-digest( https://github.com/varnish/libvmod-digest )


