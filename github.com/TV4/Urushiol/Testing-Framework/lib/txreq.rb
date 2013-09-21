module Urushiol
  class Txreq

    def initialize
      @req = "\ntxreq"
    end

    def url(url)
      @req << " -url #{url}"
    end

    def protocol(proto)
      @req << " -proto #{proto}"
    end

    def host(host)
      @req << " -hdr \"Host: #{host}\""
    end

    def request(type)
      @req << " -req #{type.upcase}"
    end

    def get_source
      @req
    end
  end
end
