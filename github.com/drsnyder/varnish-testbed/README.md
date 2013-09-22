# Varnish Test Bed

A set of tools for testing and configuring varnish. This can be particularly helpful if
you have a situation that is difficult to debug in production.

This testbed provides enough to get started with a simple backend (one or more) using
sinatra plus unicorn. It generates text HTML bodies with one or more esi includes that
also generate text. 

For my purposes, I introduced a random sleep in the esi requests to simplate a more
real-world situation where the body of the page is cached but the esi modules are not or
explicitly do not cache. 

This was originally created to test high context switching when multiple esi tags which
set the header

    Cache-Control: s-maxage=0

are inculded in high-traffic pages that are cached. To simulate this, you can request
/pages/i and observe the varnishlog for esi parsing or the request time when X-Cache denotes a HIT. 

# Getting started

    ./run-varnish /usr/sbin/varnishd 

    gem install unicorn 

    ruby -rubygems backend-server.rb  -p 8089
    # or 
    unicorn -c unicorn.conf -p 8089
    unicorn -c unicorn.conf -p 8090

    curl -I http://localhost:6083/

    for i in {1..1000}; do  echo "http://localhost:6083/pages/$i" >> urls.txt; done
    
    siege -i -f urls.txt -t 30S -c 20

# LICENCE

Copyright (C) 2013 Damon Snyder 

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
