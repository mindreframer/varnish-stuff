# encoding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'meta/version'

Gem::Specification.new do |s|
  s.name        = 'urushiol'
  s.version     =  Urushiol::VERSION
  s.date        =  Date.today.to_s
  s.required_ruby_version = ">=1.9.2"
  s.authors     = ["TV4","Karl Litterfeldt"]
  s.email       = "karl.litterfeldt@tv4.se"
  s.license     = "MIT-LICENSE"

  s.homepage    = "http://www.tv4.se"
  s.summary     = %q{Test framework written in Ruby to test varnish-cache routing and caching logic.}
  s.description = %q{Urushiol was born out of necessity. When we decided to migrate our reverse proxy routing from Apache to Varnish we noticed that this would not be a trivial matter. As the migration came to a halt due to unexpected routing errors we decided that, having a proper way of testing our configs would not be a bad idea. Urushiol is the product of that idea.}

  s.files       = Dir.glob("lib/**/*") + Dir.glob("test/**/*") + Dir.glob("meta/**/*") + Dir.glob("bin/**/*") + %w(urushiol.gemspec LICENSE README.md)
  s.executables   = %w(urushiol)
  s.require_paths = ["lib"]


end
