============
libvmod_dns
============

----------------------
Varnish DNS Module
----------------------

:Author: Kenneth Shaw
:Date: 2013-04-01
:Version: 0.1
:Manual section: 3

SYNOPSIS
========

import dns;

DESCRIPTION
===========

Provides some DNS functions to Varnish.

FUNCTIONS
=========

resolve
-----

Prototype
        ::

                resolve(STRING str)
Return value
	STRING
Description
	Resolves the hostname to its dns entry
Example
        ::

                set resp.http.x-dns-example = dns.resolve("www.example.com");
rresolve
-----

Prototype
        ::

                rresolve(STRING str)
Return value
	STRING
Description
	Reverse resolve an IP
Example
        ::

                set resp.http.x-dns-reverse = dns.rresolve("127.0.0.1");

INSTALLATION
============

This vmod is based off the libvmod-example source, and thus works / compiles
in the same fashion.

This vmod was originally built with the intention of detecting bots with bad
User-Agent strings. See the example below.

Usage::

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

        import dns;

        # do a dns check on "good" crawlers
        sub vcl_recv {
            if (req.http.user-agent ~ "(?i)(googlebot|bingbot|slurp|teoma)") {
                # do a reverse lookup on the client.ip (X-Forwarded-For) and check that its in the allowed domains
                set req.http.X-Crawler-DNS-Reverse = dns.rresolve(req.http.X-Forwarded-For);

                # check that the RDNS points to an allowed domain -- 403 error if it doesn't
                if (req.http.X-Crawler-DNS-Reverse !~ "(?i)\.(googlebot\.com|search\.msn\.com|crawl\.yahoo\.net|ask\.com)$") {
                    error 403 "Forbidden";
                }

                # do a forward lookup on the DNS
                set req.http.X-Crawler-DNS-Forward = dns.resolve(req.http.X-Crawler-DNS-Reverse);

                # if the client.ip/X-Forwarded-For doesn't match, then the user-agent is fake
                if (req.http.X-Crawler-DNS-Forward != req.http.X-Forwarded-For) {
                    error 403 "Forbidden";
                }
            }
        }

HISTORY
=======

This module was created in an effort to detect/prevent/stop clients User-Agent
strings claiming to be googlebot/msnbot/etc.

COPYRIGHT
=========

This document is licensed under the same license as the
libvmod-dns project. See LICENSE for details.

* Copyright (c) 2013 Kenneth Shaw
