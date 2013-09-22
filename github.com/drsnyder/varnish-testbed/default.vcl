backend pair1 {
    .host = "127.0.0.1";
    .port = "8089";
}

backend pair2 {
    .host = "127.0.0.1";
    .port = "8090";
}

director default random {
    {
        .backend = pair1;
        .weight = 1;
    }
    {
        .backend = pair2;
        .weight = 1;
    }
}

sub vcl_recv {
    set req.backend = default;

    if (req.restarts == 0) {
        if (req.http.x-forwarded-for) {
            set req.http.X-Forwarded-For =
                req.http.X-Forwarded-For ", " client.ip;
        } else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }
    if (req.request != "GET" &&
            req.request != "HEAD" &&
            req.request != "PUT" &&
            req.request != "POST" &&
            req.request != "TRACE" &&
            req.request != "OPTIONS" &&
            req.request != "DELETE") {
        /* Non-RFC2616 or CONNECT which is weird. */
        return (pipe);
    }
    if (req.request != "GET" && req.request != "HEAD") {
        /* We only deal with GET and HEAD by default */
        return (pass);
    }
    if (req.http.Authorization || req.http.Cookie) {
        /* Not cacheable by default */
        return (pass);
    }
    return (lookup);
}

sub vcl_pipe {
    return (pipe);
}

sub vcl_pass {
    return (pass);
}

sub vcl_hash {
    set req.hash += req.url;
    if (req.http.host) {
        set req.hash += req.http.host;
    } else {
        set req.hash += server.ip;
    }
    return (hash);
}

sub vcl_hit {
    if (!obj.cacheable) {
        return (pass);
    }
    return (deliver);
}

sub vcl_miss {
    return (fetch);
}

sub vcl_fetch {
    esi;

    if (!beresp.cacheable) {
        return (pass);
    }
    if (beresp.http.Set-Cookie) {
        return (pass);
    }

    # added to prevent high csw/s when esi modules set s-maxage=0
    if (beresp.http.Cache-Control ~ "s-maxage=0") {
        return (pass);
    }

    return (deliver);
}

sub vcl_deliver {
    set resp.http.X-Served-By = server.identity;
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }

    return (deliver);
}

sub vcl_error {
    set obj.http.Content-Type = "text/html; charset=utf-8";
    synthetic {"
        <?xml version="1.0" encoding="utf-8"?>
            <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
            "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
            <html>
            <head>
            <title>"} obj.status " " obj.response {"</title>
            </head>
            <body>
            <h1>Error "} obj.status " " obj.response {"</h1>
            <p>"} obj.response {"</p>
            <h3>Guru Meditation:</h3>
            <p>XID: "} req.xid {"</p>
            <hr>
            <p>Varnish cache server</p>
            </body>
            </html>
            "};
    return (deliver);
}
