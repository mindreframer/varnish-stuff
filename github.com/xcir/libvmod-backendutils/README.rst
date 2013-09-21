===================
vmod_backendutils
===================

-------------------------------
Varnish backend utils
-------------------------------

:Author: Syohei Tanaka(@xcir)
:Date: 2013-01-24
:Version: 0.1
:Manual section: 3

SYNOPSIS
===========

import backendutils;

DESCRIPTION
==============
Add the backend by dynamic.

THIS MODULE IS PROOF OF CONCEPT.


EXAMPLE
============

        ::

                import backendutils;
                backend default {
                    .host = "192.168.1.1";
                    .port = "8080";
                }
                sub vcl_init{
                    backendutils.initsimple(default);
                }
                sub vcl_recv{
                    set req.backend = backendutils.createsimple("dynamicBackend","192.168.1.199","88");
                }

FUNCTIONS
============



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


COPYRIGHT
=============

This document is licensed under the same license as the
libvmod-rewrite project. See LICENSE for details.

* Copyright (c) 2013 Syohei Tanaka(@xcir)

File layout and configuration based on libvmod-example

* Copyright (c) 2011 Varnish Software AS

