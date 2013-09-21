require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"



if Rails.env.production?
  # we don't like to rely on unicorn timeouts as they reap they
  # entire worker and aren't logged in Exceptional. therefore set
  # this to a value that it should never reach as a last resort
  timeout 120
end

worker_processes 6 # amount of unicorn workers to spin up

# this might help ensure that Heroku only sends traffic to a dyno once it's ready;
# it also means workers spawn really fast
preload_app true

before_fork do |server, worker|
  $config.threadsafe!

  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to sent QUIT'
  end
end

# support streaming
listen ENV["PORT"].to_i, :tcp_nopush => false, :tcp_nodelay => true
