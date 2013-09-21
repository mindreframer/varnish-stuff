module Varnish
  LIBVARNISHAPI = [
    'libvarnishapi.1',    # Mac OS X
    'libvarnishapi.so.1'  # Debian / Ubuntu
  ]
end

require 'varnish/vsm'
require 'varnish/vsl'
