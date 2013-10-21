#!/bin/sh

echo 'Reading etcd values...'
ruby /etc/varnish_etcd/varnish_etcd.rb

echo 'Starting varnish now...'
service varnish start

echo 'Varnish started, responding to requests until etcd values change'

while :;
do
  curl -L http://172.17.42.1:4001/v1/watch/domains;
  ruby /etc/varnish_etcd/varnish_etcd.rb;
  service varnish reload;
done