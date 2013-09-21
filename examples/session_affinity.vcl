#
# Cookie-based session-affinity: non-cached replies will go to a backend per
# the normal rules, but we'll keep track of the backend that served the
# request and make sure any future request from the same client will go to
# the same backend.
#

import redis;
import std;

backend be1 {
  .host = "192.168.0.1";
  .port = "80";
}

backend be2 {
  .host = "192.168.0.2";
  .port = "80";
}

director default random {
  .retries = 5;
  {
    .backend        = be1;
    .weight         = 7;
  }
  {
    .backend        = be2;
    .weight         = 3;
  }
}

#
# Compute the redis key from a request.
#
# In this example a cookie is used, but it could be anything distinctive enough;
# IP address + User Agent + Accept* headers should work nicely for most purposes.
#
sub redis_key_from_req {
  if (req.http.Cookie) {
    set req.http.redis_key = req.http.Cookie;
  }
}

#
# Compute the redis key from a response.
#
# We use the reposnse cookie if present, as it might be different. We still
# have the request headers in case we want to use a different schema (see the
# comment for redis_key_from_req).
#
# Another option is to have the backend send us an explicit header.
#
sub redis_key_from_beresp {
  if (beresp.http.Set_Cookie) {
    set req.http.redis_key = beresp.http.Set_Cookie;
  } else if (req.http.Cookie) {
    set req.http.redis_key = req.http.Cookie;
  }
}

#
# Compute the backend that will serve further requests for this user.
#
# We just use the backend name, but we may as well use an explicit header
# from the backend. This would enable other scenarios, e.g. a "master" app
# server that creates sessions and then hands them off to other servers.
#
sub backend_from_beresp {
  set beresp.http.x_backend = beresp.backend.name;
}

#
# Set a backend given the name.
#
# This would be a very useful addition to the language, or it could be
# implemented as a vmod.
#
sub set_backend_by_name {
  if (req.http.x_backend) {
    std.log("backend will be: " + req.http.x_backend);

    if (req.http.x_backend == "be1") {
      set req.backend = be1;
    } else if (req.http.x_backend == "be2") {
      set req.backend = be2;
    } else {
      error 503 "No such backend " + req.http.x_backend;
    }
  }
}

#
# This is the main subroutine; it takes care of finding whether we have an
# entry in redis, and sets the corresponding backed.
#
sub select_backend {
  call redis_key_from_req;

  if (req.http.redis_key) {
    set req.http.x_backend = redis.call("HGET sessions " + req.http.redis_key);
    if (req.http.x_backend) {
      std.log("Found in redis");
      call set_backend_by_name;
    } else {
      # we will let the director choose
    }
  } else {
    std.log("Cookie not found");
  }
}

sub vcl_miss {
  call select_backend;
}

sub vcl_pass {
  call select_backend;
}

sub vcl_pipe {
  call select_backend;
}

#
# IF we don't have an entry in redis, we just let the director (or other
# mechanism) choose. When we get the response we need to figure key and
# value and store them.
#
sub vcl_fetch {
  if (!req.http.x_backend) {
    call redis_key_from_beresp;
    call backend_from_beresp;

    if (req.http.redis_key) {
      std.log("Fetched from: " + beresp.http.x_backend + ", key=" + req.http.redis_key);
      redis.send("HSET sessions " + req.http.redis_key + " " + beresp.http.x_backend);
    }
  }
}
