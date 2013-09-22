#!/usr/bin/env ruby -rubygems
# ruby -rubygems backend-server.rb  -p 8089 
require 'sinatra'

PAYLOAD_SIZE=(2**10)

def rchr
    (97 + rand(27)).chr
end

def generate_random_block(n)
    n.times.collect { rchr }.join("")
end

def emit_body(text)
    body "<html><body>\n" + \
        text + \
        "</body></html>\n"
end

get '/pages/:unique' do
    status 200
    emit_body(
        generate_random_block(10*PAYLOAD_SIZE) + "\n" +  \
        "<esi:include src=\"/modules/esi\" />\n" + \
        "<esi:include src=\"/modules/esi\" />\n" + \
        "<esi:include src=\"/modules/esi\" />\n" + \
        generate_random_block(10*PAYLOAD_SIZE) + 
        "\n--- #{params[:unique]} ---\n")

end

get '/modules/esi' do
    # simulate a slow backend
    sleep(rand(0.3))
    status 200
    headers "Cache-Control" => "s-maxage=0"
    body generate_random_block(PAYLOAD_SIZE)
end

