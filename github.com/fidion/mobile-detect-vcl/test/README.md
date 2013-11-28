Testing mobile-detect
=====================

This directory is for our internal use only, for crosschecking newer versions before 
commits to the git repository.
It may be useful though, if you have to expand the VCL script.

checkmobiledetect.php will read the file useragentswitcher.xml 
Those Useragents will be feed to varnish using curl with method "MOBILEDETECT",
that triggers an error, writing out a short html containing also the detected flags.
These flags are be parsed.

The method "MOBILEDETECT" must be implemented in Varnish using the following in your default.vcl:

    acl adminips {
       "localhost";
       "127.0.0.0"/8;


    // to read all variables if asked from admin-ips:
    sub vcl_deliver {
       if (client.ip ~ adminips) {
          set resp.http.X-Varnish-UA-Device = req.http.X-UA-Device;
          set resp.http.X-Varnish-UA-Type = req.http.X-UA-Type ;
          set resp.http.X-Varnish-UA-Detail = req.http.X-UA-Detail ;
          set resp.http.X-Varnish-UA-OS = req.http.X-UA-OS ;
          set resp.http.X-Varnish-UA-isMobile = req.http.X-UA-isMobile ;
       } 
    }

    include "/path/to/mobile-detect.vcl";
    sub vcl_fetch {
       if (req.request == "MOBILEDETECT") {
          if (!client.ip ~ adminips) {
         error 405 "Not allowed.";
          }
          call mobiledetect;
          error 200 "MOBILEDETECT: "+server.hostname;
       }
    }


the Script checkmobile.sh calls checkmobiledetect.php and diffs it output to the default file, 
so any changes in behaviour can easily be found.
