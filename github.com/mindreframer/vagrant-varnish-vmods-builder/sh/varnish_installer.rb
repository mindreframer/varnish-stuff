#!/usr/bin/env ruby

## works on Ubuntu 12.04 with varnish 3.0.4
## will create a Deb file for latest (2013.09.23) Varnish with loads of VMODs,
## all nicely packaged into 2.5MB :)

### For trying out:
## $ apt-get install gdebi-core
## $ wget http://optimate.dl.sourceforge.net/project/mindreframerpackages/varnish-3.0.4.ubuntu.12.04_amd64.deb
## $ gdebi -n varnish-3.0.4.ubuntu.12.04_amd64.deb
## # get the list of installed VMODs
## $ ls -la /usr/local/lib/varnish/vmods

## Inspirations:
##  - https://gist.github.com/jordansissel/2777508
##  - http://lassekarstensen.wordpress.com/2013/07/29/building-a-varnish-vmod-on-debian/
##  - http://www.kreuzwerker.de/en/blog/packaging-varnish-vmods/

VARNISH_CONFIG = {
  :version  => "3.0.4",
  :tmp_path => "/var/tmp/varnish",
  :dest_dir => "/tmp/varnish",
  :prefix   => "/usr/local",
  :deps     => [
    "autotools-dev",
    "automake1.9",
    "autoconf",
    "pkg-config",
    "libtool",
    "libncurses-dev",
    "libpcre3-dev",
    "python-docutils",
    "xsltproc",
    "groff-base"
  ]
}

VMODS = [
  {
    :name => "statsd",
    :url  => "https://github.com/jib/libvmod-statsd.git",
  },
  {
    :name => "timers",
    :url  => "https://github.com/jib/libvmod-timers.git",
  },
  {
    :name => "curl",
    :url  => "https://github.com/varnish/libvmod-curl.git",
    :deps => ["libcurl4-openssl-dev"],
  },
  {
    :name => "ipcast",
    :url  => "https://github.com/lkarsten/libvmod-ipcast.git"
  },
  {
    :name => "throttle",
    :url  => "https://github.com/nand2/libvmod-throttle.git"
  },
  {
    :name => "var",
    :url  => "https://github.com/varnish/libvmod-var.git"
  },
  {
    :name => "memcached",
    :url  => "https://github.com/sodabrew/libvmod-memcached.git",
    :deps => ["libmemcached-dev"]
  },
  {
    :name => "digest",
    :url  => "https://github.com/varnish/libvmod-digest.git",
    :deps => ["libmhash-dev"]
  },
  {
    :name => "shield",
    :url  => "https://github.com/varnish/libvmod-shield.git"
  },
  {
    :name => "threescale",
    :url  => "https://github.com/3scale/libvmod-3scale.git"
  },
  {
    :name => "cookie",
    :url  => "https://github.com/lkarsten/libvmod-cookie.git"
  },
  {
    :name => "urlcode",
    :url  => "https://github.com/fastly/libvmod-urlcode.git"
  },
  {
    :name => "timeutils",
    :url  => "https://github.com/jthomerson/libvmod-timeutils.git"
  },
  {
    :name => "dgram",
    :url  => "https://github.com/mmb/vmod_dgram.git"
  },
  {
    :name => "parsereq",
    :url  => "https://github.com/xcir/libvmod-parsereq.git"
  },
  {
    :name => "header",
    :url  => "https://github.com/varnish/libvmod-header.git"
  }
]


class String
  def deindent
    lines = self.split("\n")
    min_space = lines.map{|x|
      x.strip.size == 0 ? 1000 : x.size - x.lstrip.size
    }.min
    lines.map{|x| x[min_space..-1]}.join("\n")
  end

  def black;          "\033[30m#{self}\033[0m" end
  def red;            "\033[31m#{self}\033[0m" end
  def green;          "\033[32m#{self}\033[0m" end
  def blue;           "\033[34m#{self}\033[0m" end
end

module Bannerize
  def bash_banner(msg, color=:blue)
    color_msg = "#{ '*'*20} #{msg} ".send(color)
    "echo '#{color_msg}'"
  end
end


# generator = VarnishScriptGenerator.new
# puts generator.full_script
class VarnishScriptGenerator
  attr_accessor :varnish_config
  attr_accessor :vmod_modules

  def initialize
    @varnish_config = VARNISH_CONFIG
    @vmod_modules   = VMODS
  end

  def full_script
    options = {
      :varnish_config => varnish_config,
      :vmod_modules   => vmod_modules
    }

    vmods   = vmod_modules.map do |vmod_config|
      Vmod.script(:vmod_config => vmod_config, :varnish_config => varnish_config)
    end

    varnish = Varnish.script(options)
    fpm     = FPM.script(options)

    return ([varnish] + vmods + [fpm]).join("\n\n")
  end

  class Varnish
    extend Bannerize
    def self.script(options={})
      varnish_config = options[:varnish_config]
      res = %Q[
        apt-get install -y #{varnish_config[:deps].join(" ")}
        mkdir -p #{varnish_config[:tmp_path]}
        cd #{varnish_config[:tmp_path]}

        if [ ! -d varnish ]; then
          git clone --progress --recursive git://github.com/varnish/Varnish-Cache.git varnish
        fi

        cd varnish

        git fetch
        git checkout varnish-#{varnish_config[:version]}

        #make clean
        nice ./autogen.sh
        nice ./configure --prefix=#{varnish_config[:prefix]} --sysconfdir=/etc --localstatedir=/var/lib
        umask 022  # because our default umask is stupid
        nice make
        make install DESTDIR=#{varnish_config[:dest_dir]}
      ].deindent
      [bash_banner("installing Varnish #{varnish_config[:version]}"), res].join("\n")
    end
  end

  class Vmod
    extend Bannerize
    def self.script(options={})
      vmod_config    = options[:vmod_config]
      varnish_config = options[:varnish_config]

      res = bash_banner("installing VMOD #{vmod_config[:name]}") + "\n"
      res << (vmod_deps(vmod_config[:deps]) + "\n") if vmod_config[:deps]
      res << vmod_template(vmod_config[:url], varnish_config)
      res
    end

    def self.vmod_deps(arr)
      to_install = Array(arr)
      "apt-get install -y #{to_install.join( )}"
    end

    def self.vmod_template(git_url, varnish_config)
      folder_name = File.basename(git_url).gsub(".git", "")
      res = %Q[
        cd #{varnish_config[:tmp_path]}
        if [ ! -d #{folder_name} ]; then
          git clone #{git_url}
        fi
        cd #{folder_name}
        git fetch
        ## in case the folder is not there
        mkdir -p m4
        ./autogen.sh
        ./configure --prefix=#{varnish_config[:prefix]} VARNISHSRC=#{varnish_config[:tmp_path]}/varnish VMODDIR=#{varnish_config[:prefix]}/lib/varnish/vmods
        umask 022  # because our default umask is stupid
        make
        make install DESTDIR=#{varnish_config[:dest_dir]}
      ].deindent
    end
  end

  class FPM
    extend Bannerize
    def self.script(options={})
      varnish_config = options[:varnish_config]
      vmod_modules   = options[:vmod_modules]

      lines = []
      lines << "fpm -s dir -t deb -n varnish-#{varnish_config[:version]} -v #{varnish_config[:version]} -C #{varnish_config[:dest_dir]}"
      lines << "--after-install #{varnish_config[:dest_dir]}/run-ldconfig.sh"
      lines << "--force"
      lines << "-p varnish-VERSION.#{os_string}_ARCH.deb"
      lines << "#{fpm_deps(vmod_modules)}"
      lines << "usr/local/"
      lines[0..-2].each { |e| e << '  \\'  }

      ([before_fpm(varnish_config)] + lines).join("\n")
    end

    def self.before_fpm(varnish_config)
      lines = []
      lines << bash_banner("Generating DEB file")
      lines << bash_banner("It will be in the 'pkg' folder on the host system", :red)
      lines << "printf '#!/bin/sh\nldconfig\n' > #{varnish_config[:dest_dir]}/run-ldconfig.sh"
      lines << "mkdir -p /vagrant/pkg"
      lines << "cd /vagrant/pkg"
      lines.join("\n")
    end

    def self.fpm_deps(vmod_modules)
      deps = vmod_modules.select{|x| x[:deps]}.map{|x| x[:deps]}.flatten.uniq
      deps_with_versions = deps.map do |dep|
        [dep, dep_version(dep)]
      end
      res = deps_with_versions.map do |dep_pair|
        " -d '#{dep_pair[0]} (>= #{dep_pair[1]}) '"
      end

      res.join(" ")
    end

    # read the current package version from live system
    def self.dep_version(dep_name)
      res = %x(dpkg -l |grep #{dep_name}).split[2]
      res || "0"
    end

    # get the os info
    def self.os_string
      a           = %x(cat /etc/lsb-release)
      release_num = a.split("\n")[1].split("=")[1]
      os_type     = a.split("\n")[0].split("=")[1].downcase
      os_type + "." + release_num
    end
  end
end


# installer = VarnishInstaller.new
# installer.install_vmod("header")
class VarnishInstaller
  attr_accessor :varnish_config
  attr_accessor :vmod_modules

  def initialize
    @varnish_config = VARNISH_CONFIG
    @vmod_modules   = VMODS
  end

  def install_vmod(name)
    vmod_config = vmod_modules.select{|x| x[:name] == name}.first
    script      = VarnishScriptGenerator::Vmod.script(:vmod_config => vmod_config, :varnish_config => options[:varnish_config])
    execute(script)
  end

  def install_fpm
    execute(VarnishScriptGenerator::FPM.script(options))
  end

  def install_varnish
    execute(VarnishScriptGenerator::Varnish.script(options))
  end

  def options
    {
      :varnish_config => varnish_config,
      :vmod_modules   => vmod_modules
    }
  end

  def execute(cmd)
    IO.popen(cmd) do |data|
      while line = data.gets
        puts line
      end
    end
  end
end

self_executing = (__FILE__ == $0)
run_tests      = ARGV[0] == "t"


if self_executing && !run_tests
  gen = VarnishScriptGenerator.new
  puts "# #{'*'*20} generated by varnish_installer.rb #{'*'*20}"
  puts gen.full_script
elsif self_executing && run_tests
  require 'rubygems'
  require 'minitest/unit'
  require 'minitest/spec'
  require 'minitest/mock'
  MiniTest::Unit.autorun

  class TestVarnishInstaller < MiniTest::Unit::TestCase

    describe "VarnishScriptGenerator" do
      before do
        @object = VarnishScriptGenerator.new
      end

      it "works" do
        @object.wont_be_nil
      end
    end

    describe "VarnishScriptGenerator::Varnish" do
      before do
        @object = VarnishScriptGenerator::Varnish.new
      end

      it "works" do
        @object.wont_be_nil
      end
    end

    describe "VarnishScriptGenerator::Vmod" do
      before do
        @object = VarnishScriptGenerator::Vmod.new
      end

      it "works" do
        @object.wont_be_nil
      end
    end

    describe "VarnishScriptGenerator::FPM" do
      before do
        @object = VarnishScriptGenerator::FPM.new
      end

      it "works" do
        @object.wont_be_nil
      end
    end
  end
end