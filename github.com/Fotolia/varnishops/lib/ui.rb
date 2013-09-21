require 'curses'

include Curses

class UI
  attr_accessor :sort_order, :sort_mode, :show_percent

  def initialize(config)
    @config = config

    @stat_cols    = %w[ calls req/s kB/s hitratio ]
    @stat_col_width = 15
    @key_col_width  = 30
    @avg_period = @config[:avg_period]
    @sort_mode = :reqps
    @sort_order = :desc
    @show_percent = false

    @commands = {
      'B' => "sort by bandwidth",
      'C' => "sort by call number",
      'H' => "sort by hitratio",
      'K' => "sort by key",
      'P' => "display percentages",
      'Q' => "quit",
      'R' => "sort by request rate",
      'T' => "toggle sort order (asc|desc)"
    }

    init_screen
    cbreak
    curs_set(0)

    # set keyboard input timeout - sneaky way to manage refresh rate
    Curses.timeout = @config[:refresh_rate]

    if can_change_color?
      start_color
      init_pair(0, COLOR_WHITE, COLOR_BLACK)
      init_pair(1, COLOR_WHITE, COLOR_BLUE)
      init_pair(2, COLOR_WHITE, COLOR_RED)
    end
  end

  def header
    # pad stat columns to @stat_col_width
    @stat_cols = @stat_cols.map { |c| sprintf("%#{@stat_col_width}s", c) }

    @url_col_width = cols - @key_col_width - (@stat_cols.length * @stat_col_width)

    attrset(color_pair(1))
    setpos(0,0)
    
    addstr(sprintf "%-#{@key_col_width}s%-#{@url_col_width}s%s", (@config[:host_mode]) ? "hostname" : "request pattern", "last url", @stat_cols.join)
  end

  def footer
    footer_text = @commands.map { |k,v| "#{k}:#{v}" }.join(' | ')
    setpos(lines - 1, 0)
    attrset(color_pair(2))
    addstr(sprintf "%-#{cols}s", footer_text)
  end

  def render_stats(pipe)
    render_start_t = Time.now.to_f * 1000

    # subtract header + footer lines
    maxlines = lines - 3
    offset = 1

    # construct and render footer stats line
    setpos(lines - 2, 0)
    attrset(color_pair(2))
    header_summary = sprintf "%-24s %-14s %-14s %-14s %-14s",
      "sort mode: #{@sort_mode.to_s} (#{@sort_order.to_s})",
      "| requests: #{pipe.stats[:total_reqs]}",
      "| bytes out: #{pipe.stats[:total_bytes]}",
      "| duration: #{Time.now.to_i - pipe.start_time.to_i}s",
      "| samples: #{@avg_period}"
    addstr(sprintf "%-#{cols}s", header_summary)

    # reset colours for main key display
    attrset(color_pair(0))

    top = []
    totals = {}

    pipe.semaphore.synchronize do
      # we may have seen no packets received on the pipe thread
      return if pipe.start_time.nil?

      time_since_start = Time.now.to_f - pipe.start_time
      elapsed = time_since_start < @avg_period ? time_since_start : @avg_period

      # calculate hits+misses, request rate, bandwidth and hitratio
      pipe.stats[:requests].each do |key,values|
        total_hits = values[:hit].inject(:+)
        total_calls = total_hits + values[:miss].inject(:+)
        total_bytes = values[:bytes].inject(:+)

        pipe.stats[:calls][key] = total_calls
        pipe.stats[:reqps][key] = total_calls.to_f / elapsed
        pipe.stats[:bps][key] = total_bytes.to_f / elapsed
        pipe.stats[:hitratio][key] = total_hits.to_f * 100 / total_calls
      end

      if @sort_mode == :key
        top = pipe.stats[:requests].sort { |a,b| a[0] <=> b[0] }
      else
        top = pipe.stats[@sort_mode].sort { |a,b| a[1] <=> b[1] }
      end

      totals = {
        :calls => pipe.stats[:calls].values.inject(:+),
        :reqps => pipe.stats[:reqps].values.inject(:+),
        :bps => pipe.stats[:bps].values.inject(:+)
      }
    end

    unless @sort_order == :asc
      top.reverse!
    end

    for i in 0..maxlines-1
      if i < top.length
        k = top[i][0]

        # if the key is too wide for the column truncate it and add an ellipsis
        display_key = k.length > @key_col_width ? "#{k[0..@key_col_width-4]}..." : k
        display_url = pipe.stats[:requests][k][:last]
        display_url = display_url.length > @url_col_width ? "#{display_url[0..@url_col_width-4]}..." : display_url

        # render each key
        if @show_percent
          line = sprintf "%-#{@key_col_width}s%-#{@url_col_width}s %14.2f %14.2f %14.2f %14.2f",
                   display_key, display_url,
                   pipe.stats[:calls][k].to_f / totals[:calls] * 100,
                   pipe.stats[:reqps][k] / totals[:reqps] * 100,
                   pipe.stats[:bps][k] / totals[:bps] * 100,
                   pipe.stats[:hitratio][k]
        else
          line = sprintf "%-#{@key_col_width}s%-#{@url_col_width}s %14.d %14.2f %14.2f %14.2f",
                   display_key, display_url,
                   pipe.stats[:calls][k],
                   pipe.stats[:reqps][k],
                   pipe.stats[:bps][k] / 1000,
                   pipe.stats[:hitratio][k]
        end
      else
        # clear remaining lines
        line = " "*cols
      end

      setpos(1 + i, 0)
      addstr(line)
    end

    # Display column totals
    unless @show_percent
      setpos(top.length + 2, 0)
      line = sprintf "%-#{@key_col_width + @url_col_width}s %14.d %14.2f %14.2f",
               "TOTAL", totals[:calls].to_i, totals[:reqps].to_f, totals[:bps].to_f / 1000
      addstr(line)
    end

    # print render time in status bar
    runtime = (Time.now.to_f * 1000) - render_start_t
    attrset(color_pair(2))
    setpos(lines - 2, cols - 24)
    addstr(sprintf "render time: %4.3f (ms)", runtime)
  end

  def input_handler
    # Curses.getch has a bug in 1.8.x causing non-blocking
    # calls to block reimplemented using IO.select
    if RUBY_VERSION =~ /^1.8/
      refresh_secs = @config[:refresh_rate].to_f / 1000

      if IO.select([STDIN], nil, nil, refresh_secs)
        c = getch
        c.chr
      else
        nil
      end
    else
      getch
    end
  end

  def stop
    nocbreak
    close_screen
  end
end
