backend be_musicbrainz {
 .host = "127.0.0.1";
 .port = "5000";
}

backend be_threescale {
 .host = "su1.3scale.net";
 .port = "80";
}

import std;
import threescale;

sub vcl_recv {
    unset req.http.cookie;

    if (!req.http.X-3scale-authorization) {
        # The lack of a X-3scale-authorization header means that this request 
	# has come from a client, so we need to notify 3scale
	set req.backend = be_musicbrainz;

        # This header is the URL to query 3scale with to do authorization
	set req.http.X-3scale-authrep = "/transactions/authrep.xml?provider_key=4facf5558e20b5c9e7c8ec30ddb105ec&app_id=" +
	  req.http.MusicBrainz-App-ID + "&app_key=" + req.http.MusicBrainz-App-Key + "&usage[hits]=1";

        # Authorize with 3scale (blocking)
	# Actually goes via the Varnish cache
	set req.http.X-3scale-authrep-result = threescale.send_get_request("localhost","9000",req.http.X-3scale-authrep,"X-3scale-authorization: true;");

        if (req.http.X-3scale-authrep-result == "200") {
            # The user is authorized for WS calls
        }
        else {
	    # Authorization failed, so remove their app key/ID and treat them
	    # as the inferior general public
	    unset req.http.MusicBrainz-App-ID;
	    unset req.http.MusicBrainz-App-Key;
        } 

        return(pass);
    }
    else {
        # The request has a X-3scale-authorization header, so we should talk to
	# 3scale
	set req.backend = be_threescale;
	set req.http.host = "su1.3scale.net";
        
	if (req.request != "GET" && req.request != "HEAD") {
            std.syslog(0, "Doing 3scale lookup with non-GET/HEAD request. This should never happen!");
        } 
	else {
	    return(lookup);
        }
    }
}

# A HIT means that the request to your local cache of 3scale is still fresh and
# the response will not have to fetch the data from the remote 3scale backend.
# vmod_3scale plugin will send a replica of the call asynchronously to 3scale's remote
# backend on its own
sub vcl_hit {
    if (req.http.X-3scale-authorization) {
        if (req.url ~ "^/transactions/authrep.xml\?") {
	    if (threescale.send_get_request_threaded("su1.3scale.net","80",req.url,"") == 0) {
	    }
        }
    }
}

sub vcl_fetch {
    if (req.http.X-3scale-authorization) {
        # Cache the authorization from 3scale for 30 seconds
  	set beresp.ttl = 30s;
    }
}

sub vcl_deliver {
    # Remove control headers
    unset req.http.X-3scale-authrep;
    unset req.http.X-3scale-authrep-result;
}
