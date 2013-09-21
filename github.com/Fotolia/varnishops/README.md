# varnishops

varnishops is a tool for analyzing and categorizing traffic on your varnish servers in realtime.

It gathers the output of varnishncsa and create statistics such as request rate, output bandwidth or hitratio.

URLs from varnishncsa can be categorized in two ways:
 * using custom regular expressions applied on URL, based on your assets' paths and classification (example provided in **ext/**)
 * using host header, if you have several assets domains (with -H switch)

varnishops is written in Ruby (tested with MRI 1.9.3 and MRI 1.8.7) and depends only on varnishncsa.

![varnishops](https://raw.github.com/Fotolia/varnishops/master/doc/varnishops.png)

## Setup

 * git clone https://github.com/Fotolia/varnishops
OR
 * gem install varnishops


By default, URLs will be categorized based on their extensions, and statistics computed for each type.

Categories can be added by defining filters (ruby regexps). See example file in **ext/**.

## Credits

varnishops is heavily inspired by [mctop](http://github.com/etsy/mctop) from Etsy's folks.
