# Introduction

libvmod-redis is a [varnish][varnish] [vcl][vcl] module for interacting with
[redis][redis].

# Usage

libvmod-redis makes available a series of functions used to run commands against
a remote redis server.

## Functions

For now, refer to [vmod_redis.vcc][vmod_redis_vcc]

# Errors

Note that this library has no error handling facilities. All errors are silently
ignored.

[varnish]: https://www.varnish-cache.org/
[vcl]: https://www.varnish-cache.org/docs/3.0/reference/vcl.html
[redis]: http://redis.io/
[vmod_redis_vcc]: https://github.com/academia-edu/libvmod-redis/blob/master/src/vmod_redis.vcc

<!--- vim: set noet tw=80: -->
