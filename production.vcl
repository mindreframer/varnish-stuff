include "backend.vcl";

sub vcl_deliver {
    unset resp.http.Link;
    unset resp.http.Server;
    unset resp.http.Via;
    unset resp.http.X-Drupal-Cache;
    unset resp.http.X-Powered-By;
    unset resp.http.X-Varnish;
}

sub vcl_error {
    include "error.vcl";
    return (deliver);
}
