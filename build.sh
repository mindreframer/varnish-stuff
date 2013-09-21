#!/bin/sh

./autogen.sh
./configure VARNISHSRC=$HOME/src/Varnish-Cache
make
