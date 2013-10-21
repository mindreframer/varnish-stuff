module Urushiol
  class Txreq

    def initialize
      @req = "\ntxreq"
    end

    def url(url)
      @req << " -url #{url.strip}"
    end

    def protocol(proto)
      @req << " -proto #{proto.strip}"
    end

    def host(host)
      @req << " -hdr \"Host: #{host.strip}\""
    end

    def request(type)
      @req << " -req #{type.strip.upcase}"
    end

    def get_source
      @req
    end
  end
end
