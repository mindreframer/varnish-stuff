INCLUDES = -I$(VARNISHSRC)/include -I$(VARNISHSRC) -I/usr/local/include

vmoddir = $(VMODDIR)
vmod_LTLIBRARIES = libvmod_redis.la

libvmod_redis_la_LDFLAGS = -module -export-dynamic -version-info 1:0:0
libvmod_redis_la_LIBADD = -lhiredis

libvmod_redis_la_SOURCES = \
	vcc_if.c \
	vcc_if.h \
	vmod_redis.c

vcc_if.c vcc_if.h: $(VARNISHSRC)/lib/libvmod_std/vmod.py $(top_srcdir)/src/vmod_redis.vcc
	@PYTHON@ $(VARNISHSRC)/lib/libvmod_std/vmod.py $(top_srcdir)/src/vmod_redis.vcc

EXTRA_DIST = vmod_redis.vcc

CLEANFILES = $(builddir)/vcc_if.c $(builddir)/vcc_if.h
