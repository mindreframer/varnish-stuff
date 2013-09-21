# This is a the VCL configuration file for 3scale's varnish plugin.
# 
# Default backend definition.  Set this to point to the 3scale's
# backend. 
# 
# set the beresp.ttl in vcl_fetch to have a default global TTL
# you can define custom TTL via regular expressions
#
# Integration mode: stand-alone out of band system.
# Traffic from API consumers will not go through Varnish
# (see https://support.3scale.net/howtos/api-configuration/varnish)

backend default {
  .host = "su1.3scale.net";     
  .port = "80";
}

import std;
import threescale;

sub vcl_recv {

	unset req.http.cookie;
	set req.http.host = "su1.3scale.net";
	set req.grace = 1s;

	if (req.request != "GET" && req.request != "HEAD") {
      		return(pass);
    	}
    	else {
      		## GET or HEAD requests
      		return(lookup);
    	}
	 
}

# the hash of the request needs to be customized to remove all fields that are not 
# associated to the user

sub vcl_hash {

	## remove no_body
	set req.http.X-url-tmp = regsub(req.url,"[&?]no_body.[^&]*","");
	## remove object_id
	set req.http.X-url-tmp = regsub(req.http.X-url-tmp,"[&?]object.[^&]*","");
	## remove object
	set req.http.X-url-tmp = regsub(req.http.X-url-tmp,"[&?]object_id.[^&]*","");

	hash_data(req.http.X-url-tmp);	
	unset req.http.X-url-tmp;
     	return (hash);

}

#A HIT means that the request to your local cache of 3scale is still fresh and the
#response will not have to fetch the data from the remote 3scale backend.
#vmod_3scale plugin will send a replica of the call asynchronously to 3scale's remote
#backend on its own

sub vcl_hit {

  if (req.url ~ "^/transactions/authrep.xml\?") {
	  if (req.url ~ "^/transactions/authrep.xml\?") {
	    if (threescale.send_get_request_threaded("su1.3scale.net","80",req.url,"")==0) {}
    }
  }

}


sub vcl_fetch {
	set beresp.ttl = 30s;
}



