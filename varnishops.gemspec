# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "varnishops"
  gem.version       = "0.1.0"
  gem.authors       = ["Jonathan Amiez"]
  gem.email         = ["jonathan.amiez@fotolia.com"]
  gem.description   = %q{varnishops - a realtime varnish log analyzer}
  gem.summary       = %q{varnishops - an interactive terminal app for analyzing varnish activity with hitratio, bandwidth and request rate per type of files}
  gem.homepage      = "https://github.com/Fotolia/varnishops"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]
end
