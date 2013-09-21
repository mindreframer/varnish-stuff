varnish-rb
==========

varnish-rb provides a bridge between Ruby and [Varnish 3](http://varnish-cache.org/).


Low-level access to Varnishlog
------------------------------

Low-level access to the varnishlog SHM is provided via Varnish::VSL and the underlying class Varnish::VSM.
Ruby methods are mapped to the corresponding C APIs through FFI. This guarantees extremely high performance
(around 200k entries per second) at the cost.

This API is currently undocumented, because the underlying varnishlog API is not officially supported and
subject to changes. See examples/log.rb for an example.


Varnishlog EventMachine connection
----------------------------------

EM::VarnishLog::Connection is a subclass of EM::Connection that provides a stream of log entries. It processes
log entries in a background thread outside the reactor and pushes them onto an EM::Channel. Channel subscribers
within the reactor thread can receive these entries and process them further.

Due to the complexity of using threads with EventMachine, and the need for very high performance, this API is
currently tested only on JRuby (1.6.2 as of this writing).

Pushing one log entry at a time will incur a very high overhead that limits the number of entries that can be
processed per second. This gem provides an EM::BufferedChannel that implements double buffering. Using this channel
it is possible to process about 150k entries per second, corresponding to 3-4k HTTP requests per second. This
makes it possible to process moderate traffic in a development or preproduction environment, but you would have to
be out of your mind to use it in production.

See examples/log\_tail.rb and especially examples/request\_tail.rb for a taste of how to use this API.

Contributing to varnish-rb
==========================
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Copyright
=========

Copyright (c) 2011 ZephirWorks. See LICENSE.txt for
further details.

