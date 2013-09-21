#!/usr/bin/ruby

require 'rubygems'
gem 'json'
require 'json'
require 'erb'

# curl here

# Parse response into JSON
etcd_response = File.read('/etc/varnish_etcd/etcd_sample.json')
etcd_response = JSON.parse(etcd_response)

# Fetch VCL template
recv_template = File.read('/etc/varnish_etcd/vcl_recv.erb')
recv_rules = ERB.new(recv_template)

#etcd_response.each_with_index do |domain, index|
#  puts JSON.pretty_generate(domain)
#  domain_name = domain["key"].split('/')[-1]
#  ip_addresses = domain["value"].delete("[]").split(",")
#  puts ip_addresses
#end

# Write rendered template into /etc/varnish/default.vcl
#puts recv_rules.result()
File.open('/etc/varnish/default.vcl', 'w') { |file| file.write(recv_rules.result()) }
