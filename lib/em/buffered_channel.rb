require 'eventmachine'

module EM
  #
  # A subclass of EM::Channel that implements double buffering (using a
  # circular array of arrays) to achieve higher packet rate.
  #
  # The buffer size and the number of buffers are critical to achieving good
  # performance, you may need to tune them.
  #
  class BufferedChannel < EM::Channel
    def initialize
      super
      @buffer = BufferSet.new(2000, 200)
    end

    def push(*items)
      @buffer.push(*items) do |buf|
        EM.schedule do
          @subs.values.each do |s|
            begin
              buf.each do |i|
                s.call i
              end
            ensure
              buf.clear
            end
          end
        end
      end
    end

    class BufferSet
      def initialize(size, nbufs)
        @size = size
        @nbufs = nbufs

        @buffers = []

        setup
      end

      def push(data)
        raise "WTF #{@buffers.length}" unless @buffers.length == @nbufs

        if @buffers[0].length > @size
          if @buffers[1].length > 0
            raise "panic! the next buffer is still full!"
          end

          buf = @buffers.shift
          @buffers << buf

          yield buf
        end

        @buffers.first << data
      end

    private
      def setup
        (0..@nbufs-1).each do |n|
          @buffers[n] = []
        end
      end
    end
  end
end
