# Description

Installs and configures [Varnish](https://www.varnish-cache.org/) HTTP Accelerator. Varnish is installed from the [varnish-cache.org] repos to ensure the most up to date stable release is available. All aspects of the software can be tuned using the attributes available within the cookbook.

[![Build Status](https://secure.travis-ci.org/inviqa/chef-varnish.png?branch=master)](http://travis-ci.org/inviqa/chef-varnish)

# Requirements

Chef 0.10.0 or higher required (for Chef environment use).

## Platform

* Debian, Ubuntu
* CentOS, Red Hat, Fedora

## Cookbooks

The following Opscode cookbooks are dependencies:

* apt | yum

# Attributes

Available attributes and default values:

* `node['varnish']['daemon_config']` = "/etc/sysconfig/varnish"
* `node['varnish']['config_dir']` = "/etc/varnish"
* `node['varnish']['VARNISH_VCL_CONF']` = "/etc/varnish/default.vcl"
* `node['varnish']['VARNISH_LISTEN_PORT']` = 6081
* `node['varnish']['VARNISH_BACKEND_PORT']` = 80
* `node['varnish']['VARNISH_BACKEND_ADDRESS']` = "127.0.0.1"
* `node['varnish']['VARNISH_ADMIN_LISTEN_ADDRESS']` = "127.0.0.1"
* `node['varnish']['VARNISH_ADMIN_LISTEN_PORT']` = 6082
* `node['varnish']['VARNISH_SECRET_FILE']` = "/etc/varnish/secret"
* `node['varnish']['VARNISH_MIN_THREADS']` = 1
* `node['varnish']['VARNISH_MAX_THREADS']` = 1000
* `node['varnish']['VARNISH_THREAD_TIMEOUT']` = 120
* `node['varnish']['VARNISH_STORAGE_FILE']` = "/var/lib/varnish/varnish_storage.bin"
* `node['varnish']['VARNISH_STORAGE_SIZE']` = "1G"
* `node['varnish']['VARNISH_STORAGE']` = "malloc" # file | malloc | persistent
* `node['varnish']['VARNISH_TTL']` = 120


# Recipes

## default

Adds the varnish-cache.org repository to apt or yum depending upon the base platform. Then installs the latest 3.* build of Varnish applying configuration based on the attributes defined within the recipe.

# License and Author

Author:: Alistair Stead (alistair@inviqa.com)

Copyright 2012, Inviqa

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

