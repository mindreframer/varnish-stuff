require 'eventmachine'
require 'varnish'

module EM
  module VarnishLog
    #
    # A subclass of EM::Connection that reads from the Varnish log SHM and
    # pushes single log entries on the channel passed to its constructor.
    #
    # Note that simply using an EM::Channel pretty much guarantees awful
    # performance, suitable only for extremely low workloads in a development
    # environment. The provided EM::BufferedChannel improves things quite a
    # bit: it has proved able to push about 150k entries per second
    # (corresponding to about 4k HTTP req/s), using a full CPU on a modern
    # MBP.
    #
    class Connection
      class << self
        attr_reader :channel
      end

      def initialize(channel)
        @channel = channel
      end

      def run
        vd = Varnish::VSM.VSM_New
        Varnish::VSL.VSL_Setup(vd)
        Varnish::VSL.VSL_Open(vd, 1)

        callback = Proc.new { |*args| cb(*args) }

        Thread.new do
          begin
            Varnish::VSL.VSL_Dispatch(vd, callback, FFI::MemoryPointer.new(:pointer))
          rescue => e
            puts "exception in thread: #{e.inspect}"
          ensure
            EM.stop
          end
        end
      rescue => e
        puts "exception in post_init: #{e.inspect}"
      end

    private
      def cb(priv, tag, fd, len, spec, ptr, bitmap)
        str = ptr.read_string(len)
        @channel.push(:tag => tag, :fd => fd, :data => str, :spec => spec, :bitmap => bitmap)
        0 # ok
      rescue => e
        puts "exception in cb: #{e.inspect}"
      end
    end
  end
end
