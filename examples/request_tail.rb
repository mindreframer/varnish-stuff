require 'eventmachine'
require File.expand_path('request_stream', File.dirname(__FILE__))

EM.run do
  count = 0
  t = nil

  stream = RequestStream.new
  stream.onrequest do |data|
    t = Time.now if count == 0
    count += 1
    if (count % 1000) == 0
      puts "received #{count} requests in #{(Time.now - t).to_s} seconds"
      t = Time.now
    end
  end
end
