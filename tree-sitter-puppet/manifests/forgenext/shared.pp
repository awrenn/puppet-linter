class profile::forgenext::shared {
  sysctl::value { 'net.core.somaxconn':
    value  => '2048',
    notify => Service['nginx'],
  }

  sysctl::value { 'net.core.netdev_max_backlog':
    value  => '2048',
    notify => Service['nginx'],
  }

  file { '/etc/nginx/legacy-proxy.conf':
    ensure => present,
    source => 'puppet:///modules/profile/forgenext/web/forge-legacy-proxy.conf',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Service['nginx'],
  }
}
