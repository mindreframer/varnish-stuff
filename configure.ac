AC_PREREQ(2.59)
AC_COPYRIGHT([Copyright (c) 2013 Academia.edu AS])
AC_INIT([libvmod-redis], [trunk])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_SRCDIR(src/vmod_redis.vcc)
AC_CONFIG_HEADERS(config.h)

AC_CANONICAL_SYSTEM
AC_LANG(C)

AM_INIT_AUTOMAKE([foreign])

AC_GNU_SOURCE
AC_PROG_CC
AC_PROG_CC_STDC
if test "x$ac_cv_prog_cc_c99" = xno; then
	AC_MSG_ERROR([Could not find a C99 compatible compiler])
fi
CFLAGS="$CFLAGS -pedantic -Wextra -Wall -Werror"

AC_PROG_INSTALL
AC_PROG_LIBTOOL
AC_PROG_MAKE_SET

# Check for rst utilities
AC_CHECK_PROGS(RST2MAN, [rst2man rst2man.py], "no")
if test "x$RST2MAN" = "xno"; then
	AC_MSG_WARN([rst2man not found - not building man pages])
fi
AM_CONDITIONAL(HAVE_RST2MAN, [test "x$RST2MAN" != "xno"])

# Check for pkg-config
PKG_PROG_PKG_CONFIG

# Checks for header files.
AC_HEADER_STDC
AC_HEADER_ASSERT
AC_CHECK_HEADERS([sys/stdlib.h])

# Check for python
AC_CHECK_PROGS(PYTHON, [python3 python3.1 python3.2 python2.7 python2.6 python2.5 python2 python], [AC_MSG_ERROR([Python is needed to build this vmod, please install python.])])

# Varnish source tree
AC_ARG_WITH(
	[varnish],
	[AS_HELP_STRING([--with-varnish], [path to the Varnish source tree])],
	[VARNISHSRC="$withval"],
	[AC_MSG_ERROR([No Varnish source tree specified])]
)
AC_SUBST([VARNISHSRC])

AC_CHECK_FILE(
	[$VARNISHSRC/include/varnishapi.h],
	[],
	[AC_MSG_FAILURE(["$VARNISHSRC" is not a Varnish source directory])]
)

# Check that varnishtest is built in the varnish source directory
AC_CHECK_FILE(
	[$VARNISHSRC/bin/varnishtest/varnishtest],
	[],
	[AC_MSG_FAILURE([Can't find "$VARNISHSRC/bin/varnishtest/varnishtest". Please build your varnish source directory])]
)

# vmod installation dir
AC_ARG_VAR([VMODDIR], [vmod installation directory @<:@LIBDIR/varnish/vmods@:>@])
if test "x$VMODDIR" = x; then
	VMODDIR=`pkg-config --variable=vmoddir varnishapi`
	if test "x$VMODDIR" = x; then
		AC_MSG_FAILURE([Can't determine vmod installation directory])
	fi
fi

# Hiredis library
AC_ARG_WITH(
	[hiredis-include-path],
	[AS_HELP_STRING([--with-hiredis-include-path], [path to the Hiredis headers])],
	[HIREDIS_CFLAGS="-I$withval"],
	[]
)
AC_SUBST([HIREDIS_CFLAGS])

AC_ARG_WITH(
	[hiredis-lib-path],
	[AS_HELP_STRING([--with-hiredis-lib-path], [path to the Hiredis library])],
	[HIREDIS_LIBS="-L$withval -lhiredis"],
	[HIREDIS_LIBS="-lhiredis"]
)
AC_SUBST([HIREDIS_LIBS])

PKG_CHECK_MODULES([GLIB], [glib-2.0])

AC_CONFIG_FILES([
	Makefile
	src/Makefile
])
AC_OUTPUT
