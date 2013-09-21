require 'optparse'

class CmdLine
  def self.parse(args)
    @config = {}

    opts = OptionParser.new do |opt|
      @config[:config_file] = File.join(File.dirname(File.dirname(__FILE__)), 'config.rb')
      opt.on '-c', '--config-file=FILE', String, 'Config file containing regular expressions to categorize traffic' do |config_file|
        @config[:config_file] = File.expand_path(config_file)
      end

      @config[:refresh_rate] = 500
      opt.on '-r', '--refresh=MS', Integer, 'Refresh the stats display every MS milliseconds' do |refresh_rate|
        @config[:refresh_rate] = refresh_rate
      end

      @config[:avg_period] = 60
      opt.on '-a', '--avg-period=SEC', Integer, 'Compute averages over SEC seconds' do |avg_period|
        @config[:avg_period] = avg_period
      end

      @config[:host_mode] = false
      opt.on '-H', '--host-mode', "Categorize requests using hostnames instead of url regexps" do |host_mode|
        @config[:host_mode] = true
      end

      opt.on_tail '-h', '--help', 'Show usage info' do
        puts opts
        exit
      end
    end

    opts.parse!

    # limit data structures size
    @config[:avg_period] = 600 if @config[:avg_period] > 600
    @config[:avg_period] = 10 if @config[:avg_period] < 10

    unless File.exists?(@config[:config_file])
      puts "#{@config[:config_file]}: no such file"
      exit 1
    end

    unless ENV['PATH'].split(File::PATH_SEPARATOR).any? {|d| File.executable?(File.join(d, "varnishncsa"))}
      puts "varnishncsa not found. install it or set a correct PATH"
      exit 1
    end

    @config
  end
end
