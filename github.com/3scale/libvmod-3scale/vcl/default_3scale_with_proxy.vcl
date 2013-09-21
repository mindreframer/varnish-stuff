# This is a the VCL configuration file for 3scale's varnish plugin.
# 
# Default backend definition.  Set this to point to the 3scale's
# backend. 
# 
# set the beresp.ttl in vcl_fetch to have a default global TTL
# you can define custom TTL via regular expressions
#
# Integration mode: API proxy.
# Traffic from API consumers will go through Varnish 
# Varnish will check with 3scale backend for API call authorization and reporting
# (see https://support.3scale.net/howtos/api-configuration/varnish)

# Replace placeholders at lines 18, 19 and 42.

## the backend of your API
backend backend_api {
  .host = "YOUR_API_ENDPOINT";     
  .port = "YOUR_API_ENDPOINT";
}

## real 3scale backend
backend backend_3scale {
  .host = "su1.3scale.net";     
  .port = "80";
}

import std;
import threescale;

sub vcl_recv {

  unset req.http.cookie;

  if (!req.http.X-3scale-authorization) {
    ## this request was send by the end-user
    set req.backend = backend_api;

    ## need to generate the string for the 3scale authorization,
    set req.http.X-3scale-authrep = "/transactions/authrep.xml?provider_key=";
    ## set your 3scale provider_key
    ## set req.http.X-3scale-authrep = req.http.X-3scale-authrep + "YOUR_PROVIDER_KEY";
    
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

    ## set the appropriate usage in a similar why than above, the basic one is...
    set req.http.X-3scale-authrep = req.http.X-3scale-authrep + "&usage[hits]=1"; 

    ## now the additional paramters, for instance if you want to pass the url path 
    set req.http.X-3scale-authrep = req.http.X-3scale-authrep + "&object=" + req.url;

    set req.http.X-3scale-authrep-result = threescale.send_get_request("localhost","80",req.http.X-3scale-authrep,"X-3scale-authorization: true;");

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
  else {
    ## the request was not send by the end-user but by varnish itself
    set req.backend = backend_3scale;
    set req.http.host = "su1.3scale.net";

    if (req.request != "GET" && req.request != "HEAD") {
      std.syslog(0,"This should never happen!!");
    } 
    else {
      return(lookup);
    }

  }

	 
}

# the hash of the request needs to be customized to remove all fields that are not 
# associated to the user

sub vcl_hash {

  if (req.http.X-3scale-authorization) {  
    ## remove no_body
    set req.http.X-url-tmp = regsub(req.url,"[&?]no_body.[^&]*","");
    ## remove object_id
    set req.http.X-url-tmp = regsub(req.http.X-url-tmp,"[&?]object.[^&]*","");
    ## remove object
    set req.http.X-url-tmp = regsub(req.http.X-url-tmp,"[&?]object_id.[^&]*","");

    hash_data(req.http.X-url-tmp);	
    unset req.http.X-url-tmp;
  }
  else {
    ## the default has of varnish for the end-user request, however we better remove the 
    ## parameters specific to 3scale from the end-user request. If you want to remove other
    ## parameters from the original request so that they are not taken into account for the
    ## cache this is the place.

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

  }

  return (hash);

}

#A HIT means that the request to your local cache of 3scale is still fresh and the
#response will not have to fetch the data from the remote 3scale backend.
#vmod_3scale plugin will send a replica of the call asynchronously to 3scale's remote
#backend on its own

sub vcl_hit {

  if (req.http.X-3scale-authorization) {
    if (req.url ~ "^/transactions/authrep.xml\?") {
	    if (threescale.send_get_request_threaded("su1.3scale.net","80",req.url,"")==0) {}
    }
  }
  

}


sub vcl_fetch {

  if (req.http.X-3scale-authorization) {
    ## cache the authorization from 3scale
  	set beresp.ttl = 30s;
  }
  else {
    ## cache of the content of your API
	  set beresp.ttl = 60s;
  }

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
      <p><b>Please go to your account at 3scale to find out</b></p>
    </div>
  </body>
</html>
"};
  return (deliver);
}




