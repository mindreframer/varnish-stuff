==============
vmod_urlfilter
==============

-------------------------
Varnish Url Filter Module
-------------------------

:Author: psicosi448
:Date: 2013-09-26
:Version: 1.0
:Manual section: 3

SYNOPSIS
========

import urlfilter;

DESCRIPTION
===========

This Varnish vmod sanitize STRING to get a canonical version.
A canonical name does not contain any ".", ".." components nor "/".

FUNCTIONS
=========

canonicalize
------------

Prototype
        ::

                canonicalize(STRING S)
Return value
	STRING
Description
	Return the canonical absolute name of string S. A canonical name
        does not contain any ".", ".." components nor any repeated file 
        name separators ('/').
Example
        ::

                set req.url = urlfilter.canonicalize(req.url);

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

In your VCL you could then use this vmod along the following lines::
        
        import urlfilter;
        
        sub vcl_recv {
          set req.url = urlfilter.canonicalize(req.url);
        }

HISTORY
=======

This manual page was released as part of the libvmod-urlfilter 
package.

When reviewing logs, we notice strange request urls. Requests 
originated from malicious script trying to access an admin/ location.

A restriction similar to req.url ~ "^/+admin" didn't succeed with a
request url encoded and with relative locations: %2f%2E%2fadmin%2f

We've decided to develop a varnish module to filter client's 
requests, inspired by coreutils canonicalize.c function:
http://fossies.org/dox/coreutils-8.21/canonicalize_8c_source.html

We use it, in conjunction with curl.unescape, to secure and sanitize
strange req.url input like:
/.../one///two//three///four../five/.%2e/%2E.//six/%2E%2e/%2e./seven

to obtain a more comfortble req.url:
/.../one/two/seven

COPYRIGHT
=========

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

* Copyright (C) 1996-2013 Free Software Foundation, Inc.
