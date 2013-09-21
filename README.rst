============
vmod_dgram
============

----------------------
Varnish Dgram Module
----------------------

:Author: Matthew M. Boedicker
:Date: 2013-05-30
:Version: 1.0
:Manual section: 3

SYNOPSIS
========

import dgram;

sub vcl_deliver {
  dgram.send(req.request + " " + req.http.host + req.url, "127.0.0.1", 12345);
}

DESCRIPTION
===========

Varnish module to send arbitrary data over UDP from VCL.

The original use case is a hit counter that will send the URL served for
every request to a simple UDP server for further processing.

FUNCTIONS
=========

dgram
-----

Prototype
        ::

                send(STRING S, STRING HOST, INT PORT)
Return value
	VOID
Description
        Sends S as UDP to HOST:PORT.
Example
        ::

                dgram.send("Hello world", "127.0.0.1", 12345);

INSTALLATION
============

The source tree is based on autotools to configure the building, and
does also have the necessary bits in place to do functional unit tests
using the varnishtest tool.

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

HISTORY
=======

COPYRIGHT
=========

* Copyright (c) 2013 Matthew M. Boedicker
