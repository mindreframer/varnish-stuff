# This is a the VCL configuration file for 3scale's varnish plugin.
# 
# Default backend definition.  Set this to point to the 3scale's
# backend. 
# 
# set the beresp.ttl in vcl_fetch to have a default global TTL
# you can define custom TTL via regular expressions
#

## the backend of your API
backend backend_api {
  .host = "YOU API ENDPOINT, for instance api.mydomain.com"; 
  .port = "80";
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
    ##set req.backend = backend_api;

    ## need to generate the string for the 3scale authorization,
    set req.http.X-3scale-auth = "/transactions/oauth_authorize.xml?provider_key=";
    ## set your 3scale provider_key
    set req.http.X-3scale-auth = req.http.X-3scale-auth + "CHANGEME: YOUR 3SCALE PROVIDER_KEY";
    
    ## extract the parameters sent by the user
    set req.http.X-3scale-app_id = regsub(req.url,".*[&?]app_id.([^&]*).*","\1");
    
    set req.http.X-3scale-auth = req.http.X-3scale-auth + "&app_id=" + req.http.X-3scale-app_id;  
    
    ## set the appropriate usage in a similar way than above, the basic one is...
    set req.http.X-3scale-auth = req.http.X-3scale-auth + "&usage[hits]=1";
    ## if you need to add the service_id
    #set req.http.X-3scale-auth = req.http.X-3scale-auth + "&service_id=SERVICE_ID";
    
    ## build the request for the report
    set req.http.X-3scale-report = "provider_key=" + "CHANGEME: YOUR 3SCALE PROVIDER_KEY";
    #set req.http.X-3scale-report = req.http.X-3scale-report + "&service_id=";
    #set req.http.X-3scale-report = req.http.X-3scale-report + "CHANGEME: SERVICE_ID";
    set req.http.X-3scale-report = req.http.X-3scale-report + "&transactions[0][app_id]=";
    set req.http.X-3scale-report = req.http.X-3scale-report + req.http.X-3scale-app_id;
    
    ## set the usage, you can specify the metric that you want
    set req.http.X-3scale-report = req.http.X-3scale-report + "&transactions[0][usage][hits]=1";
    ## -----
    
    unset req.http.X-3scale-app_id;
    
    set req.http.X-3scale-auth-res = threescale.send_get_request_body("localhost","CHANGEME: THE PORT THAT VARNISH IS LISTENING TO",req.http.X-3scale-auth,"X-3scale-authorization: true;");

    set req.http.X-3scale-auth-code = threescale.response_http_code(req.http.X-3scale-auth-res);

    ## THE OAUTH SECRET FROM THE APPLICATION WILL BE SENT TO THE API BACKEND
    set req.http.X-3scale-auth-secret = threescale.response_key(req.http.X-3scale-auth-res);

    unset req.http.X-3scale-auth-res;
    unset req.http.X-3scale-auth;

    
    if (req.http.X-3scale-auth-code == "200") {
      ## the request has been authorized, proceed as normal. Send always to the backend.
      ## because we always do a pass, no caching of the backend. 

      unset req.http.X-3scale-auth-code;
      if (threescale.send_post_request_threaded("su1.3scale.net","80","/transactions.xml","",req.http.X-3scale-report)==0) {} 
      unset req.http.X-3scale-auth-report;

      return(pass);
    }
    else {
      ## the request from the users has not been authorized!! Returning an error
      ## FIXME: convert req.http.X-3scale-authrep-result; to int

      unset req.http.X-3scale-auth-code;
      error 401;
    } 
        
  }
  else {
    ## the request was not send by the end-user but by varnish itself
    set req.backend = backend_3scale;
    set req.http.host = "su1.3scale.net";
    set req.grace = 5s;

    if (req.request != "GET" && req.request != "HEAD") {
      std.log("This should never happen!!");
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
    if (req.url ~ "^/transactions/oauth_authorize.xml\?") {
	    ##if (threescale.send_get_request_threaded("su1.3scale.net","80",req.url,"")==0) {}
    }
  }

}


sub vcl_fetch {

  if (req.http.X-3scale-authorization) {
    ## cache the authorization from 3scale
    ## CHANGEME: below the TTL of the response of 3scale's backend
  	set beresp.ttl = 60s;
  }
  else {
  
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




