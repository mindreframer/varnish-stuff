============
vmod_uuid
============

----------------------
Varnish UUID Module
----------------------

:Author: Mitchell Broome
:Date: 2013-08-01
:Version: 1.0
:Manual section: 3

SYNOPSIS
========

import uuid;

DESCRIPTION
===========

UUID Varnish vmod used to generate a uuid.


FUNCTIONS
=========

uuid
-----

Prototype
        ::

                uuid()
Return value
	STRING
Description
	Returns a uuid
UUID
        ::

                set req.http.X-Flow-ID = "cache-" + uuid.uuid();


DEPENDENCIES
============

Libvmod-uuid requires the OSSP uuid library to generate uuids.  It
is available at http://www.ossp.org/pkg/lib/uuid/ or possibly as a
prepackaged library from your linux distribution.  i

In the case of Redhat/Fedora/CentOS, the rpm is named uuid.  Ensure
you install the rpms with the following command::

   yum install -y uuid uuid-devel


INSTALLATION
============

This is a basic implementation to generate a uuid for use in varnish.

The source tree is based on autotools to configure the building, and
does also have the necessary bits in place to do functional unit tests
using the varnishtest tool.

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

In your VCL you could then use this vmod along the following lines::
        
        import uuid;

        sub vcl_recv {
                # This sets req.http.X-Flow-ID to "cache-uuid"
                set req.http.X-Flow-ID = "cache-" + uuid.uuid();
        }


COPYRIGHT
=========

This document is licensed under the same license as the
libvmod-uuid project. See LICENSE for details.

