# This is a the VCL configuration file for 3scale's varnish plugin.
# 
# Default backend definition.  Set this to point to the 3scale's
# backend. 
# 
# set the beresp.ttl in vcl_fetch to have a default global TTL
# you can define custom TTL via regular expressions
#

## the backend of your API
backend origin_server {
  .host = "YOU_ORIGIN_API_HOSTNAME";     
  .port = "80";
}

import std;
import threescale;

sub vcl_recv {

  unset req.http.cookie;


  ## this request was send by the end-user
  set req.backend = origin_server;
    
  set req.http.X-3scale-authrep = "/transactions/authrep.xml?provider_key=YOUR_PROVIDER_KEY";

  ## ------------------
  ## MAPPING OF METHODS
  ## ------------------

  if (req.url ~ "^/deals/") {
    set req.http.X-3scale-authrep = req.http.X-3scale-authrep + "&usage[deals]=1";
  }

  if (req.url ~ "^/sales/local") {
    set req.http.X-3scale-authrep = req.http.X-3scale-authrep + "&usage[sales]=1&usage[local]=1";
  }
  
  ## ----------------------
  ## END MAPPING OF METHODS
  ## ----------------------

  ## extract the parameters sent by the user
  set req.http.X-3scale-app_id = regsub(req.url,".*[&?](app_id.[^&]*).*","\1");
  set req.http.X-3scale-app_key = regsub(req.url,".*[&?](app_key.[^&]*).*","\1");
  set req.http.X-3scale-user_key = regsub(req.url,".*[&?](user_key.[^&]*).*","\1");
  set req.http.X-3scale-user_id = regsub(req.url,".*[&?](user_id.[^&]*).*","\1");

  if (req.http.X-3scale-app_id != req.url) {
    set req.http.X-3scale-authrep = req.http.X-3scale-authrep + "&" + req.http.X-3scale-app_id;  
  }

  if (req.http.X-3scale-app_key != req.url ) {
    set req.http.X-3scale-authrep = req.http.X-3scale-authrep + "&" + req.http.X-3scale-app_key;  
  }

  if (req.http.X-3scale-user_id != req.url) {
    set req.http.X-3scale-authrep = req.http.X-3scale-authrep + "&" + req.http.X-3scale-user_id;  
  }

  if (req.http.X-3scale-user_key != req.url) {
    set req.http.X-3scale-authrep = req.http.X-3scale-authrep + "&" + req.http.X-3scale-user_key;  
  }
   
  unset req.http.X-3scale-app_id;
  unset req.http.X-3scale-app_key;
  unset req.http.X-3scale-user_id;
  unset req.http.X-3scale-user_key;


  set req.http.X-3scale-authrep-result = threescale.send_get_request("su1.3scale.net","80",req.http.X-3scale-authrep,"");

  if (req.http.X-3scale-authrep-result == "200") {
    ## the request from the user has been authorized, proceed as normal

    if (req.request != "GET" && req.request != "HEAD") {
      return(pass);
    } 
    else {
      return(lookup);
    }
      
  }
  else {
    ## the request from the users has not been authorized!! Returning an error
    ## FIXME: convert req.http.X-3scale-authrep-result; to int
    error 401;
  } 

  unset req.http.X-3scale-authrep;
  unset req.http.X-3scale-authrep-result;

	 
}

# the hash of the request needs to be customized to remove all fields that are not 
# associated to the user

sub vcl_hash {

  set req.http.X-url-tmp = regsub(req.url,"[&?]user_key.[^&]*","");
  set req.http.X-url-tmp = regsub(req.url,"[&?]user_id.[^&]*","");
  set req.http.X-url-tmp = regsub(req.url,"[&?]app_key.[^&]*","");
  set req.http.X-url-tmp = regsub(req.url,"[&?]app_id.[^&]*","");

  hash_data(req.http.X-url-tmp);

  if (req.http.host) {
    hash_data(req.http.host);
  } 
  else {
    hash_data(server.ip);
  }
 
  unset req.http.X-url-tmp;

  return (hash);

}

#A HIT means that the request to your local cache of 3scale is still fresh and the
#response will not have to fetch the data from the remote 3scale backend.
#vmod_3scale plugin will send a replica of the call asynchronously to 3scale's remote
#backend on its own

sub vcl_fetch {
  ## 5 minutes caching for everything
  set beresp.ttl = 5m;
}

sub vcl_deliver {
  ## remove control headers
  unset req.http.X-3scale-authrep;
}



sub vcl_error {
  set obj.http.Content-Type = "text/html; charset=utf-8";
  synthetic {"
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <title>"} + obj.status + " " + obj.response + {"</title>
  </head>
  <body>
    <div style="background-color:yellow;">
      <h2>Authorization error trying to access this API</h2>
      <p>Did you forget to send your credentials?</p>
      <p>Are you over the limits of your account?</p> 
      <p><b>Please go to your account at http://your3scaledomain.com to find out</b></p>
    </div>
  </body>
</html>
"};
  return (deliver);
}

