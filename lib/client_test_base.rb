require 'txreq'

module Urushiol
  class ClientTestBase
    class << self
      def wait(name = "c")
        "\nclient #{name} -wait"
      end
    end
    def initialize (name,config = "")
      @client_test = "\nclient #{name} #{config}{"
    end

    def txreq(&block)
      req = Txreq.new
      yield req if block_given?
      @client_test << req.get_source
    end

    def rxresp
      @client_test << "\nrxresp"
    end

    def expect(criteria)
      @client_test << "\nexpect #{criteria.strip}"
    end

    def run
      @client_test << "\n} -run"
    end

    def test_source
      if @client_test.end_with?("\n} -run")
        @client_test
      else
        run
        @client_test
      end
    end
  end
end