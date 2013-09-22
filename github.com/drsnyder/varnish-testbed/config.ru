require 'sinatra'

set :env,  :production
disable :run

require './backend-server.rb'

run Sinatra::Application

