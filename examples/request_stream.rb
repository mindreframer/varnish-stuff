require 'em/varnish_log/connection'
require 'em/buffered_channel'

class RequestStream
  def initialize
    @channel = EM::BufferedChannel.new
    @callbacks = []

    listen
  end

  def onrequest(&block)
    @callbacks << block
  end

private

  def listen
    EM::VarnishLog::Connection.new(@channel).run

    @channel.subscribe do |msg|
      if msg[:tag] == :reqend
        @callbacks.each { |c| c.call(msg) }
      end
    end
  end
end
