# Purger

Purge varnish via bans. Work in pair with https://github.com/hellvinz/purgerd

## Installation

Add this line to your application's Gemfile:

    gem 'purger'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install purger

## Usage

The purger in a singleton that you need to configure via config! (be sure to put the same address as in purgerd)

To issue a purge call the method purge with a pattern (that varnish bans understand)

```
require 'purger'
purger = Purger.instance
purger.config!('127.0.0.1', '8080') unless purger.configured
error = purger.purge(".*.jpg")
puts 'purged!' unless error
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
