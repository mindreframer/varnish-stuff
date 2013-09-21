Exec {
  path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
}

include ufw

class varnish ($domain = undef,$backends = undef, $vhosts=undef) {
  package {'apache2':
    ensure => purged
  }
  service {'apache2':
    ensure => stopped
  }
  apt::ppa { 'ppa:ondrej/varnish': }
  package {'varnish':
    ensure => latest
  }
  service {'varnish':
    ensure     => running,
    name       => 'varnish',
    enable     => true,
    hasrestart => true,
    require    => Package['varnish'],
    subscribe  => [File['varnish-settings'],File['default.vcl']]
  }
  file {'default.vcl':
    ensure     => file,
    path       => '/etc/varnish/default.vcl',
    require    => Package['varnish'],
    content    => template('varnish/vcl.erb')
  }
  file {'varnish-settings':
    ensure     => file,
    path       => '/etc/default/varnish',
    require    => Package['varnish'],
    content    => template('varnish/varnish.erb')
  }
  file {'varnish-monitor':
    ensure     => file,
    path       => '/etc/varnish/monitor.sh',
    mode       => '0755',
    require    => Package['varnish'],
    content    => template('varnish/monitor.erb')
  }
  include xinetd
  xinetd::service {'http-alt':
    port       => '8080',
    server     => '/etc/varnish/monitor.sh',
    bind       => '127.0.0.1',
  }
  file {'varnish.vcl':
    ensure     => absent,
    path       => '/etc/varnish/varnish.vcl',
  }
  ufw::allow { 'allow-http':
    ip   => 'any',
    port => 80
  }
}
