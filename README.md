# New Relic Varnish Extension

## Instructions for running the Varnish extension agent

1. Go to [the tags list](https://github.com/varnish/newrelic_varnish_plugin/tags) and find the latest tar.gz
2. Download and extract the source
3. run `bundle install` to install required gems
4. Copy `config/template_newrelic_plugin.yml` to `config/newrelic_plugin.yml`
5. Edit `config/newrelic_plugin.yml` and replace "YOUR_LICENSE_KEY_HERE" with your New Relic license key
6. Edit the `config/newrelic_plugin.yml` if you are running Varnish
   with an -n argument
7. Execute `./newrelic_varnish_plugin`
8. Go back to the Extensions list and after a brief period you will see an entry for your extension

## Feedback, discussions and problems

The plugin can be discussed in the [Google group][group].  Bugs can be
reported on the [Github tracker][ghbugs] and pull requests are welcome.

  [group]: https://groups.google.com/a/varnish-software.com/forum/#!forum/newrelic
  [ghbugs]: https://github.com/varnish/newrelic_varnish_plugin/issues
