==============
vmod_timeutils
==============

-------------------------
Varnish Time Utils Module
-------------------------

:Manual section: 3
:Author: Jeremy Thomerson
:Date: 2012-10-17
:Version: 0.1

SYNOPSIS
========

::

	import timeutils;

	timeutils.rfc_format(<duration>);
	timeutils.expires_from_cache_control(<duration>);
	timeutils.version()

DESCRIPTION
===========

Varnish Module (vmod) that assists with date-related functions in VCL,
including manipulation of date-formatted headers.  For instance, if you
always want to add a specific amount of time to an Expires header, this
module provides an easy way to do so.

FUNCTIONS
=========

Example VCL::

	backend some_backend { ... };

	import timeutils;

	sub vcl_deliver {
		// always set the expires header ten minutes from now
		set resp.http.Expires = timeutils.rfc_format(now + 10m);
		// set the Expires header from the max-age value returned in the
		// Cache-Control response header if it is there, otherwise 15m from now
		set resp.http.Expires = timeutils.expires_from_cache_control(15m);
		// only useful for debugging, returns the version of timeutils:
		set resp.http.X-TimeUtils-Version = timeutils.version();
	}

expires_from_cache_control
--------------------------

Prototype
	timeutils.expires_from_cache_control(<default_duration>)
Returns
	string
Description
	Tries to obtain the max-age value from the `resp` Cache-Control header
	and use it to calculate a new Expires date.  If the Cache-Control header
	does not exist or the max-age value can not be determined, this will use
	your default duration and add it to the current time, returning a formatted
	date of now + `default_duration`.
Example
	``set resp.http.Expires = timeutils.expires_from_cache_control(30m);``

rfc_format
----------

Prototype
	timeutils.rfc_format(<duration>)
Returns
	string
Description
	Formats a date represented by `duration` into an RFC compliant format.
	Using default VCL ``set resp.http.Expires = now + 10m`` would result in
	a double value - the number of seconds since the epoch.  Using
	rfc_format will allow you to do those date calculations and return a
	properly formatted date.
Example
	``set resp.http.Expires = timeutils.rfc_format(now + 30m);``

version
-------

Prototype
	timeutils.version()
Returns
	string
Description
	Returns the string constant version-number of the timeutils vmod.
	Primarily useful only for debugging.
Example
	``set resp.http.X-TimeUtils-Version = timeutils.version();``


INSTALLATION
============

Installation requires the Varnish source tree (only the source matching the
binary installation).

1. `./autogen.sh`  (for git-installation)
2. `./configure VARNISHSRC=/path/to/your/varnish/source/varnish-cache`
3. `make`
4. `make install` (may require root: sudo make install)
5. `make check` (Optional for regression tests)

VARNISHSRCDIR is the directory of the Varnish source tree for which to
compile your vmod. Both the VARNISHSRCDIR and VARNISHSRCDIR/include
will be added to the include search paths for your module.

Optionally you can also set the vmod install dir by adding VMODDIR=DIR
(defaults to the pkg-config discovered directory from your Varnish
installation).


ACKNOWLEDGEMENTS
================

This plugin was heavily influenced by two modules developed by the Varnish team:
vmod_header and vmod_example.

Author: Jeremy Thomerson <jeremy@thomersonfamily.com>, Expert Tech Services, LLC

HISTORY
=======

Version 0.1: Initial version, with two simple but useful functions.  My first vmod ever.

BUGS
====

I'm sure there will be some.  Leaving this as a placeholder to document them.

SEE ALSO
========

* varnishd(1)
* vcl(7)
* https://github.com/jthomerson/libvmod-timeutils

COPYRIGHT
=========

This document is licensed under the same license as the
libvmod-timeutils project. See LICENSE for details.

* Copyright (c) 2012 Jeremy Thomerson, Expert Tech Services, LLC
