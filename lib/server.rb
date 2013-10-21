require 'txresp'

module Urushiol
  class Server
    class << self
      def wait(name)
        "\nserver #{name} -wait"
      end
    end

    def initialize (name)
      @server_string = "\nserver #{name} {"
    end

    def txresp
      resp = Txresp.new
      yield resp if block_given?
      @server_string << resp.get_source
    end

    def rxreq
      @server_string << "\nrxreq"
    end

    def expect(criteria)
      @server_string << "\nexpect #{criteria}"
    end

    def start
      @server_string << "\n} -start"
    end

    def server_source
      if @server_string.end_with?("\n} -start")
        @server_string
      else
        start
        @server_string
      end
    end
  end
end