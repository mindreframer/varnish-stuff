#!/bin/bash

str=`varnishadm -T localhost:6082 -S /etc/varnish/secret backend.list 2>&1`
if [ $? -eq 0 ]; then
   echo -en "HTTP/1.0 200 OK\r\n"
   echo -en "Server: varnish monitor\r\n"
   echo -en "Content-Type: text/plain; charset=utf-8\r\n"
   echo -en "Connection: close\r\n"
   echo -en "Content-Length: `expr ${#str} + 2`\r\n"
   echo
   echo -en "$str\r\n\r\n"
else
   echo -en "HTTP/1.0 500 Server Error ${str}\r\n"
   echo -en "Server: varnish monitor\r\n"
   echo
fi
