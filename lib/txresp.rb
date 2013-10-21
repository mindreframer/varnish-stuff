module Urushiol
  class Txresp

    def initialize
      @resp = "\ntxresp"
    end

    def message(msg)
      @resp << " -msg #{msg}"
    end

    def protocol(proto)
      @resp << " -proto #{proto}"
    end

    def status_code(status)
      @resp << " -status #{status}"
    end

    def header(hdr)
      @resp << " -hdr \"#{hdr}\""
    end

    def body(body)
      @resp << " -body \"#{body}\""
    end

    def get_source
      @resp
    end
  end
end
