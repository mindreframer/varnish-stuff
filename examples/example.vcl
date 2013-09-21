#
# A trivial example to demonstrate how to use this vmod
#

import lua;

backend be1 {
  .host = "192.168.0.1";
  .port = "80";
}

sub vcl_init {
  #
  # The function lua.init() initialize a lua state struct to be used in
  # other functions.
  #
  lua.init();
}

sub vcl_recv {
  #
  # lua.dofile_void is a procedure, it will execute the external lua script,
  # and return nothing.
  #
  lua.dofile_void("bar.lua");

  #
  # lua.dofile_str is a function that call a external lua file and return the
  # return value as a string.
  #
  set req.http.x-lua = lua.dofile_str("foo.lua");
}
