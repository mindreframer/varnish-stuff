============
vmod_timers
============

----------------------
Varnish timers Module
----------------------

:Author: Jos Boumans
:Date: 2012-08-22
:Version: 1.0
:Manual section: 3

SYNOPSIS
========

                import timers;

                sub vcl_init {
                    # Optional, defaults to milliseconds
                    timers.unit( "microseconds" );
                }

                sub vcl_deliver {
                    ### In seconds since the epoch, with 3 decimal points
                    set resp.http.x-req_start       = timers.req_start();
                    set resp.http.x-req_end         = timers.req_end();

                    ### As a timestamp. like "Fri, 24 Aug 2012 19:48:03 GMT"
                    set resp.http.x-req_start_ts    = timers.req_start_as_string();
                    set resp.http.x-req_end_ts      = timers.req_end_as_string();

                    ### Durations as an int, in your choice of units (see timers.unit)
                    ### Time from connection accept to delegation to backend
                    set resp.http.x-req_handle_time     = timers.req_handle_time();

                    ### Time from delegation to backend to first byte from backend
                    set resp.http.x-req_response_time   = timers.req_response_time();
                }


DESCRIPTION
===========

Varnish Module (vmod) for accessing various timers from Varnish.

The duration counters are compatible with usage in vmod_statsd (see below).


FUNCTIONS
=========

unit
----

Prototype::

                unit(STRING S)

Return value
	NONE
Description
    Set the base unit of durations. Your choices are: "seconds", "milliseconds",
    "microseconds" and "nanoseconds". Best used in vcl_init. Defaults to "milliseconds"

Example::

                timers.unit( "nanoseconds" );

req_start
---------

Prototype::

                req_start();

Return value
	REAL

Description
    Returns the start time of the request, in seconds since the epoch, as a number with 3
    decimal places.	Can be used in vcl_recv and onwards.

Example::

                # Will set the header to something like: 1345837683.704
                set resp.http.x-req_start = timers.req_start();

req_end
-------

Prototype::

                req_end();

Return value
	REAL
Description
    Returns the end time of the request, in seconds since the epoch, as a number with 3
    decimal places.	Can be used in vcl_deliver and onwards.

Example::

                # Will set the header to something like: 1345837683.704
                set resp.http.x-req_end = timers.req_end();

req_start_as_string
-------------------

Prototype::

                req_start_as_string()

Return value
	STRING
Description
	Returns the start time of the request, formatted as an HTTP compatible timestamp.
	Can be used in vcl_recv and onwards.

Example::

                # Will set the header to something like: Fri, 24 Aug 2012 19:48:03 GMT
                set resp.http.x-req_start_ts = timers.req_start_as_string();

req_end_as_string
-----------------

Prototype::

                req_end_as_string()

Return value
	STRING
Description
	Returns the end time of the request, formatted as an HTTP compatible timestamp.
	Can be used in vcl_deliver and onwards.

Example::

                # Will set the header to something like: Fri, 24 Aug 2012 19:48:03 GMT
                set resp.http.x-req_end_ts = timers.req_end_as_string();

req_handle_time
---------------

Prototype::

                req_handle_time()

Return value
	INT
Description
	Return the time it took from the client connection being accepted to the request
	being handed off to a backend. Note that multiple requests can come in over the
	same connection, and that the start marker for this is the accepted connection;
	other requests may have been handled during this time!
	The unit for this value is determinted by timers.unit and defaults to milliseconds.
	Can be used in vcl_recv and onwards.

	This duration is compatible with usage in vmod_statsd (see below)

Example::

                # Will set the header to something like: 119
                set resp.http.x-req_handle_time = timers.req_handle_time();

req_response_time
-----------------

Prototype::

                req_response_time()

Return value
	INT
Description
	Return the time it took from when the request was handed off to a backend until the
	first byte was returned from that backend. This is the effectively the server response
	time.
	The unit for this value is determinted by timers.unit and defaults to milliseconds.
	Can be used in vcl_deliver and onwards.

	This duration is compatible with usage in vmod_statsd (see below)

Example::

                # Will set the header to something like: 119
                set resp.http.x-req_response_time = timers.req_response_time();



INSTALLATION
============

If you received this packge without a pre-generated configure script, you must
have the GNU Autotools installed, and can then run the 'autogen.sh' script. If
you received this package with a configure script, skip to the second
command-line under Usage to configure.

Usage::

 # Generate configure script
 ./autogen.sh

 # Execute configure script
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


SEE ALSO
========

* https://github.com/jib/libvmod-statsd
* https://www.varnish-cache.org
* http://jiboumans.wordpress.com/2013/02/27/realtime-stats-from-varnish/
* https://gist.github.com/jib/5034755

COPYRIGHT
=========

This document is licensed under the same license as the
libvmod-timers project. See LICENSE for details.

* Copyright (c) 2012 Jos Boumans
