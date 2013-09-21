require "purger/version"
require "singleton"
require "timeout"
require "socket"

class Purger
  #Singleton because we don't want to have lots of connections to the purge forwarder
  include Singleton
  attr_reader :purger_host
  attr_reader :purger_port
  attr_reader :configured

  def initialize
    @configured = false
  end

  def config!(host, port) 
    return :already_configured if configured
    @purger_host = host
    @purger_port = port
    @configured = true
    return nil
  end

  def purge(pattern=".*")
    return :not_configured unless @configured
    Timeout::timeout(5) {
      socket = TCPSocket.open(purger_host,purger_port)
      socket.write(pattern)
      socket.close()
      return nil
    }
  rescue Timeout::Error
    return :timeout
  rescue
    return :error
  end
end
