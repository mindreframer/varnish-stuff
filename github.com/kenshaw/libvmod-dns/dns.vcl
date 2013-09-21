#########################################################################################################
#########################################################################################################
# include headers for comparing x-forwarded-for against acl
C{
    #include <netinet/in.h>
    #include <string.h>
    #include <sys/socket.h>
    #include <arpa/inet.h>
}C
#########################################################################################################
#########################################################################################################

# import used libraries 
import geoip;
import dns;

sub vcl_recv {
    #########################################################################################################
    #########################################################################################################
    // this is c code to allow matching from behind a proxy, using the X-Forwarded-For header
    // taken from http://zcentric.com/2012/03/16/varnish-acl-with-x-forwarded-for-header/
    C{
        // This is a hack from Igor Gariev (gariev hotmail com):
        // Copy IP address from "X-Forwarded-For" header
        // into Varnish's client_ip structure.
        // This works with Varnish 3.0.1; test with other versions
        //
        // Trusted "X-Forwarded-For" header is a must!
        // No commas are allowed. If your load balancer something other
        // than a single IP, then use a regsub() to fix it.
        struct sockaddr_storage *client_ip_ss = VRT_r_client_ip(sp);
        struct sockaddr_in *client_ip_si = (struct sockaddr_in *) client_ip_ss;
        struct in_addr *client_ip_ia = &(client_ip_si->sin_addr);

        char *xff_ip = VRT_GetHdr(sp, HDR_REQ, "\020X-Forwarded-For:");
        if (xff_ip != NULL) {
            // Copy the ip address into the struct's sin_addr.
            inet_pton(AF_INET, xff_ip, client_ip_ia);
        }
    }C
    #########################################################################################################
    #########################################################################################################

    # setup the x-forwarded-for to be correct (since it was forged above), and set the looked up geoip country
    set req.http.X-Forwarded-For = client.ip;
    set req.http.X-GeoIP-Country = geoip.country(req.http.X-Forwarded-For);

    # do a dns check on "good" crawlers
    if (req.http.user-agent ~ "(?i)(googlebot|bingbot|slurp|teoma)") {
        # do a reverse lookup on the client.ip (X-Forwarded-For) and check that its in the allowed domains
        set req.http.X-Crawler-DNS-Reverse = dns.rresolve(req.http.X-Forwarded-For);

        # check that the RDNS points to an allowed domain -- 403 error if it doesn't
        if (req.http.X-Crawler-DNS-Reverse !~ "(?i)\.(googlebot\.com|search\.msn\.com|crawl\.yahoo\.net|ask\.com)$") {
            error 403 "Forbidden";
        }

        # do a forward lookup on the DNS
        set req.http.X-Crawler-DNS-Forward = dns.resolve(req.http.X-Crawler-DNS-Reverse);

        # if the client.ip/X-Forwarded-For doesn't match, then the user-agent is fake 
        if (req.http.X-Crawler-DNS-Forward != req.http.X-Forwarded-For) {
            error 403 "Forbidden";
        }
    }
}
