class profile::forge::shared {
  ::logstashforwarder::file { 'forge_nginx_access':
    paths  => [ '/var/log/nginx/*.access.log' ],
    fields => { 'type' => 'nginx_access_json' },
  }
  ::logstashforwarder::file { 'forge_nginx_error':
    paths  => [ '/var/log/nginx/*.error.log' ],
    fields => { 'type' => 'nginx_error' },
  }

  file { '/etc/nginx/legacy-proxy.conf':
    ensure => present,
    source => 'puppet:///modules/profile/forge/lb/forge-legacy-proxy.conf',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Service['nginx'],
  }

  # Setup additional firewall rules.
  # Note: the following rules are in addtion to the default rules
  # found on a base instance.
  firewall {'100 allow http and https':
    dport  => ['80','443'],
    proto  => 'tcp',
    action => 'accept',
  }

  firewall {'100 allow http and https v6':
    dport    => ['80','443'],
    proto    => 'tcp',
    action   => 'accept',
    provider => 'ip6tables',
  }

  sysctl::value { 'net.core.somaxconn':
    value  => '2048',
    notify => [Service['nginx'], Unicorn::App['forge-web'], Unicorn::App['forge-api']],
  }

  sysctl::value { 'net.core.netdev_max_backlog':
    value  => '2048',
    notify => [Service['nginx'], Unicorn::App['forge-web'], Unicorn::App['forge-api']],
  }
}
