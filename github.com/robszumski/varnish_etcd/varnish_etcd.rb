#!/usr/bin/ruby

require 'rubygems'
gem 'json'
require 'json'
require 'pp'
require 'erb'
require 'net/http'

# Parse response into JSON
etcd_response = `curl -L http://172.17.42.1:4001/v1/keys/domains`
etcd_response = JSON.parse(etcd_response)

# Fetch VCL template
recv_template = File.read('/etc/varnish_etcd/vcl_recv.erb')
recv_rules = ERB.new(recv_template)

# Construct array of etcd data
domains = Hash.new
domains_with_default = Hash.new
etcd_response.each_with_index do |domain_data, index|
  # Store the domain we're working with
  domain = domain_data["key"].split('/')[-1] 
  # Request hostnames within the specifc domain directory
  directory = domain_data["key"]
  hostnames = `curl -L http://172.17.42.1:4001/v1/keys#{directory}`
  hostnames = JSON.parse(hostnames)
  formatted_hostnames = Array.new
  hostnames.each_with_index do |hostname, index|
    # Parse out hostname and port
    hostname_with_port = hostname["key"].split('/')[-1]
    hostname = hostname_with_port.split(':')[0]
    port = hostname_with_port.split(':')[1]
    # Store hostnames
    formatted_hostnames << Hash["hostname" => hostname, "port" => port]
  end
  ## Remove default route
  domains_with_default[domain] = formatted_hostnames
  domains = domains_with_default.reject {|domain,hostname| domain == "default"}
end

# Write rendered template into /etc/varnish/default.vcl
puts recv_rules.result()
File.open('/etc/varnish/default.vcl', 'w') { |file| file.write(recv_rules.result()) }
