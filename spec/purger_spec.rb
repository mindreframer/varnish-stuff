require 'minitest/spec'
require 'minitest/autorun'
require './lib/purger'

describe Purger do
  after do
    instance = Purger.instance
    instance.instance_variable_set(:@purger_host, nil)
    instance.instance_variable_set(:@purger_port, nil)
    instance.instance_variable_set(:@configured, false)
  end

  it "should not be configured by default" do
    Purger.instance.configured.must_equal false
  end

  it "should be configured" do
    instance = Purger.instance
    instance.config!('localhost', 3128).must_be_nil
    instance.configured.must_equal true
    instance.purger_host.must_equal 'localhost'
    instance.purger_port.must_equal 3128
  end

  it "should not be reconfigured" do
    instance = Purger.instance
    instance.config!('localhost', 3128)
    Purger.instance.config!('bim',1234).must_equal :already_configured
  end

  it "should return :not_configured when the purge is called on a non configured object" do
    instance = Purger.instance
    Purger.instance.purge(".*bla").must_equal :not_configured
  end

  it "should return :error when the purge failed" do
    instance = Purger.instance
    instance.config!('localhost', 0)
    Purger.instance.purge(".*bla").must_equal :error
  end

  it "should return nil when the purge succeed" do
    server = TCPServer.new('127.0.0.1', 0)
    instance = Purger.instance
    instance.config!('localhost', server.addr[1])
    Purger.instance.purge(".*bla").must_be_nil
  end
end
