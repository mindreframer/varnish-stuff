# -*- mode: ruby -*-
# vi: set ft=ruby :

## pls install vagrant-cachier before running
## $ vagrant plugin install vagrant-cachier

Vagrant.configure("2") do |config|
  config.vm.box = "precise64"
  config.cache.enable :apt
  config.cache.enable :gem
  config.cache.enable_nfs  = true
  config.ssh.forward_agent = true

  # for our custom packages
  config.vm.synced_folder "pkg", "/var/tmp/pkg", nfs: true

  config.vm.provider :virtualbox do |vb|
    # Give enough horsepower
    vb.customize [
      "modifyvm", :id,
      "--memory", "1536",
      "--cpus", "2"
    ]
  end

  config.vm.define 'box1' do |c|
    c.vm.hostname = "box1"
    c.vm.box      = "precise64"
    c.vm.network :private_network, ip: "192.168.251.101"
    c.vm.provision :shell, :path => "sh/provision"
  end

  config.vm.define 'box2' do |c|
    c.vm.hostname = "box2"
    c.vm.box      = "precise64"
    c.vm.network :private_network, ip: "192.168.251.102"
    c.vm.provision :shell, :path => "sh/provision"
  end
end