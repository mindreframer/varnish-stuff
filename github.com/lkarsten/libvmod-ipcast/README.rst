============
vmod_ipcast
============

----------------------
Varnish ipcast Module
----------------------

:Author: Lasse Karstensen
:Date: 2013-10-05
:Version: 1.0
:Manual section: 3

SYNOPSIS
========

import ipcast;

DESCRIPTION
===========

This is a Varnish 3.0 VMOD for inserting a VCL string into
the client.ip internal variable.

FUNCTIONS
=========

clientip
--------

Prototype
        ::

                clientip(STRING S)
Return value
	INT

Description
	Parse the IPv4/IPv6 address in S, and set that to client.ip. If
	successfull a value of 0 is returned.

	If parsing the IP address with getaddrinfo() fails, the error
	message will be logged to varnishlog and client.ip is left untouched.
	A non-zero return code will be set.


        ::

                ipcast.clientip("192.168.0.10");
                ipcast.clientip("2001:db8::1");

INSTALLATION
============

The source tree is based on autotools to configure the building, and
does also have the necessary bits in place to do functional unit tests
using the varnishtest tool.

Usage::

 # only if you are building from a git clone.
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

In your VCL you could then use this vmod along the following lines::

        import ipcast;
        acl friendly_network {
            "192.0.2.0"/24;
        }
        sub vcl_recv {
            if (req.http.X-Forwarded-For !~ ",") {
                set req.http.xff = req.http.X-Forwarded-For;
            } else {
                set req.http.xff = regsub(req.http.X-Forwarded-For,
                        "^[^,]+.?.?(.*)$", "\1");
            }

            if (ipcast.clientip(req.http.xff) != 0) {
                error 400 "Bad request";
            }

            if (client.ip !~ friendly_network) {
                    error 403 "Forbidden";
            }
        }

HISTORY
=======

This manual page is released as part of the libvmod-ipcast package. It
is based on the example document in the libvmod-example package.

COPYRIGHT
=========

This document is licensed under the same license as the
libvmod-ipcast project. See LICENSE for details.

* Copyright (c) 2011-2013 Varnish Software
