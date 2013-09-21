# -*- encoding: utf-8 -*-
require File.expand_path('../lib/purger/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Vincent Hellot"]
  gem.email         = ["hellvinz@gmail.com"]
  gem.description   = %q{A tool to purge varnish from ruby}
  gem.summary       = %q{A ruby client to http://github.com/hellvinz/purgerd for forwarding bans to varnish}
  gem.homepage      = "http://github.com/hellvinz/purger"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "purger"
  gem.require_paths = ["lib"]
  gem.version       = Purger::VERSION

  gem.add_development_dependency "minitest"
  gem.add_development_dependency "mocha"
  gem.add_development_dependency "yard"
  gem.add_development_dependency "redcarpet"
  gem.test_files = Dir.glob('spec/*_spec.rb')
end
