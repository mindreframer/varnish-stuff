require 'varnish'

class Log
  def initialize
    @vd = Varnish::VSM.VSM_New
    Varnish::VSL.VSL_Setup(@vd)
    Varnish::VSL.VSL_Open(@vd, 1)

    @count = 0
    @t = nil
  end

  def run
    Varnish::VSL.VSL_Dispatch(@vd, self.method(:callback).to_proc, FFI::MemoryPointer.new(:pointer))
  end

private
  def callback(*args)
    @t = Time.now if @count == 0
    @count += 1

    if (@count % 100000) == 0
      puts "received #{@count} messages in #{(Time.now - @t).to_s} seconds"
      @t = Time.now
    end
    return 0
  end
end

Log.new.run
