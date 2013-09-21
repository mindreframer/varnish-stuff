source 'https://rubygems.org'

gem 'rails', '3.2.13'

ruby '1.9.3'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'pin_point'

gem 'mongoid'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

group :development do
  gem 'rack-esi'
  gem 'thin'
end

group :production do
  gem 'rack-cache'
  gem 'unicorn'
  gem 'memcachier'
  gem 'dalli'
end

gem 'jquery-rails'
