require 'eventmachine'
require 'em/varnish_log/connection'
require 'em/buffered_channel'

EM.run do
  count = 0
  t = nil

  channel = EM::BufferedChannel.new
  stream = EM::VarnishLog::Connection.new(channel)
  stream.run

  channel.subscribe do |msg|
    t = Time.now if count == 0
    count += 1
    if (count % 100000) == 0
      puts "received #{count} messages in #{(Time.now - t).to_s} seconds"
      t = Time.now
    end
  end
end
