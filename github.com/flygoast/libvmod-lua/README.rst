============
vmod_lua
============

----------------------
Varnish Lua Module
----------------------

:Author: FengGu
:Date: 2013-05-30
:Version: 0.1
:Manual section: 3

SYNOPSIS
========

import lua;

DESCRIPTION
===========

Varnish lua vmod is a module to let you can execute lua script in VCL.

STATUS
======

Proof of concept

FUNCTIONS
=========

init
-----

Prototype
        ::

                init()
Return value
	VOID
Description
	Initialize a lua state struct to be used.
Example
        ::

                lua.init()

dofile_void
------------

Prototype
        ::

                dofile_void(STRING S)
Return value
	VOID
Description
	Execute the lua script specified by S
Example
        ::

                lua.dofile_void("foo.lua")

dofile_str
------------

Prototype
        ::

                dofile_str(STRING S)
Return value
	STRING
Description
	Execute the lua script specified by S, and return a string
Example
        ::

                set resp.http.x-lua = lua.dofile_str("foo.lua")

dofile_int
------------

Prototype
        ::

                dofile_int(STRING S)
Return value
	INT
Description
	Execute the lua script specified by S, and return a INT
Example
        ::

                lua.dofile_int("foo.lua")

DEPENDENCIES
============

* liblua (http://www.lua.org)

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

In your VCL you could then use this vmod along the following lines::
        
        import lua;

        sub vcl_deliver {
                set resp.http.x-lua = lua.dofile_str("foo.lua");
        }


COPYRIGHT
=========

This document is licensed under the same license as the
libvmod-lua project. See LICENSE for details.

* Copyright (c) 2013 FengGu <flygoast@gmail.com>
