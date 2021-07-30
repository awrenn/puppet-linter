class profile::haproxy (
  Optional[String[1]] $package_ensure = 'present',
  Optional[String[1]] $log_format = '{"type":"haproxy","timestamp":%Ts,"http_status":%ST,"http_request":"%r","remote_addr":"%ci","bytes_read":%B,"upstream_addr":"%si","backend_name":"%b","retries":%rc,"bytes_uploaded":%U,"upstream_response_time":"%Tr","upstream_connect_time":"%Tc","session_duration":"%Tt","termination_state":"%ts","unique-id":"%ID","request_headers":"%hr"}',

  # Per haproxy process max active connections, additional requests will
  # queue in the kernel socket until net.core.somaxconn is reached.
  Optional[Integer] $maxconn_global = 4000,

  # Default max active connections per frontend, can be overridden in
  # the frontend config.
  Optional[Integer] $maxconn_default = undef,
){
  $resolved_maxconn_default = $maxconn_default ? {
    undef => $maxconn_global,
    default => $maxconn_default,
  }

  if $resolved_maxconn_default > $maxconn_global {
    notify { 'maxconn_default_ineffective':
      message => "Configuration of \$maxconn_default (${resolved_maxconn_default}) > \$maxconn_global (${maxconn_global}) will have no effect!",
    }
  }

  Ssl::Cert::Haproxy <| |> {
    notify => Service['haproxy'],
  }

  file { '/etc/haproxy/certs.d':
    ensure  => 'directory',
    owner   => 'root',
    group   => '0',
    mode    => '0755',
    purge   => true,
    recurse => true,
    notify  => Service['haproxy'],
  }

  if $facts['os']['name'] == 'Debian' and $facts['os']['release']['major'] == '8' {
    include apt::backports

    # needed to get haproxy 1.7
    apt::pin { 'haproxy-backports':
      packages => 'haproxy',
      release  => "${facts['os']['distro']['codename']}-backports",
      priority => '1000',
      require  => Class['apt::backports'],
    }
    # libssl1.0.0 is required by the backported haproxy
    apt::pin { 'libssl100-backports':
      packages => 'libssl1.0.0',
      release  => "${facts['os']['distro']['codename']}-backports",
      priority => '1000',
      require  => Class['apt::backports'],
    }
  }

  class { '::haproxy':
    package_ensure   => $package_ensure,
    global_options   => {
      'log'                       => '/dev/log local0',
      'chroot'                    => '/var/lib/haproxy',
      'pidfile'                   => '/var/run/haproxy.pid',
      'maxconn'                   => $maxconn_global,
      'user'                      => 'haproxy',
      'group'                     => 'haproxy',
      'daemon'                    => '',
      'stats'                     => 'socket /var/lib/haproxy/stats level admin',
      'maxsslrate'                => '1000',
      'tune.ssl.default-dh-param' => hiera('ssl::dh_param_bits'),
      'ssl-default-bind-ciphers'  => hiera('ssl::ciphers'),
    },
    defaults_options => {
      'mode'             => 'http',
      'log'              => 'global',
      'maxconn'          => $resolved_maxconn_default,
      'unique-id-format' => '%{+X}o\ %ci:%cp_%fi:%fp_%Ts_%rt:%pid',
      'unique-id-header' => 'X-Unique-ID',
      'option'           => [
        'redispatch',
      ],
      'retries'          => '3',
      'balance'          => 'roundrobin',
      'timeout'          => [
        'http-request 10s',
        'queue 1m',
        'connect 10s',
        'client 1m',
        'server 1m',
        'check 10s',
      ],
      'log-format'       => $log_format,
    },
  }

  # haproxyctl is a CLI tool for interacting with haproxy
  package { 'haproxyctl':
    ensure   => 'present',
    provider => 'gem',
  }

  logrotate::job { 'haproxy':
    log        => '/var/log/haproxy.log',
    options    => [
      'size 100M',
      'daily',
      'rotate 3',
      'copytruncate',
      'missingok',
      'notifempty',
      'compress',
      'delaycompress',
    ],
    postrotate => [
      'invoke-rc.d rsyslog rotate >/dev/null 2>&1 || true',
    ],
  }

  # Debian and Centos log a bit differently
  # This should ideally mirror logs
  if $facts['os']['family'] == 'redhat' {
    file { '/var/lib/haproxy/dev/':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      require => Package['haproxy'],
    }
    file { '/etc/rsyslog.d/49-haproxy.conf':
      ensure  => present,
      content => template('profile/haproxy/49-haproxy.conf.epp'),
      notify  => Service['rsyslog'],
      require => File['/var/lib/haproxy/dev/'],
    }
  }

  if $::profile::server::params::metrics {
    include profile::haproxy::metrics
  }
  if $profile::server::params::monitoring {
    include profile::haproxy::monitor
  }
}
