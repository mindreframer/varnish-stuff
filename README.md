vcl-cache-validation
====================

VCL scripts for Varnish Cache to enforce cache content validation.

Goal
----
The goal of this project is to provide VCL (Varnish Configuration Language) scripts to help turn Varnish into a reverse-proxy client-side cache.

Motivation
----------
The main motivation for this was to have a caching layer around an internal HTTP service we have at my employer, [YouGov][yg]. This system uses [Shoji][shoji] for object representation and manipulation. The biggest way to get performance increases for this type of system is to take advantage of caching.

We want to achieve this by providing clients with a type of cache which can be used as a client-focused cache (letting the cache know what's best when it comes to returning content), but can also be used a server-side cache,

[shoji]: http://www.aminus.org/rbre/shoji/shoji-draft-02.txt
[yg]: http://www.yougov.com/

Backstory
---------
Most clients using this system demand that the data is fresh. When documents are modified using PUT requests, this should invalidate any cached representation of that document. Furthermore, fulfilling GET requests to this system can be expensive, and we should take advantage of caching if possible. If a client has a cached representation of a document, and it is able to ask the server to validate its representation, and the server can indicate the validity of that representation without going through the expense of regenerating it, then that is a ''good thing''.

In our real world use-case, being able to avoid generating responses for some resources, while being able to validate they were up-to-date is a very desirable goal. To reduce the amount of document generation (by virtue of caching), my suggestion was to have a caching layer in front of the server, rather than relying on every client being capable of caching. This would reduce the amount of work for everyone who want to be a user of the service, and a shared cache for all clients would mean a larger proportion of cache hits.

I looked at various systems to achieve this, and decided that Varnish would be a good fit, as it seemed much more configurable than other systems like Nginx. I also read somewhere that Varnish would perform cache validation on each request, so that seemed to be what we were after.

After a lot of experimentation, I realised that Varnish didn't do this at all. In fact, Varnish isn't even a caching proxy as described in [RFC2616][rfc2616] - it is more of a basic (yet very configurable and fast) accelerator for content.

[rfc2616]: http://www.w3.org/Protocols/rfc2616/rfc2616.html

So I then spent some time trying to see if I could implement this sort of validation. And after a lot of experimentation, I could - even though Varnish didn't make it easy (mainly due to lack of certain values or information being unavailable until much later in the request processing workflow). The results of which are made available in this repository.
