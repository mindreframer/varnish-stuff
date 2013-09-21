PREFIX?=/usr/local
CFLAGS=-ansi -pedantic -W -Wall
# CFLAGS=-g -Wall
LDFLAGS=-pthread
VPATH = .:bstrlib
BUILDDIR = build

all: xvo
xvo: bstrlib.o

clean:
	rm xvo
	rm -f *.o
	rm -rf *.dSYM
