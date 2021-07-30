class profile::logging::logstash::rsyslog {

  include profile::logging::logstash
  $ssldir = '/etc/puppetlabs/puppet/ssl'

  # OPS-5252 - restart rsyslog every 6 hours to prevent spooling
  cron { 'rsyslog-restart':
    command => '/etc/init.d/rsyslog restart; /etc/init.d/logstash restart',
    user    => 'root',
    hour    => '*/6',
    minute  => fqdn_rand(60),
  }

  class { '::rsyslog::server':
    enable_udp => true,
    server_dir => '/srv/log/',
    ssl        => true,
    ssl_ca     => "${ssldir}/certs/ca.pem",
    ssl_cert   => "${ssldir}/certs/${facts['networking']['fqdn']}.pem",
    ssl_key    => "${ssldir}/private_keys/${facts['networking']['fqdn']}.pem",
  }

  $input_syslog = @(INPUT_SYSLOG)
    input {
      file {
        path => [ "/srv/log/*/syslog", "/srv/log/*/auth.log", "/srv/log/*/cron.log", "/srv/log/ldap/debug", "/srv/log/vc-app-/kern.log", "/srv/log/syslog","/srv/log/web/drupal.log"]
        type => "syslog"
      }
    }
    | INPUT_SYSLOG

  logstash::configfile { 'input_syslog':
    content => $input_syslog,
    order   => 1,
  }

  @@haproxy::balancermember { "${fqdn}-rsyslog_${facts['classification']['stage']}":
    listening_service => "logstash-rsyslog_${facts['classification']['stage']}",
    server_names      => $facts['networking']['hostname'],
    ipaddresses       => $facts['networking']['ip'],
    ports             => '514',
    options           => 'check',
  }

  logrotate::job { 'rsyslog':
    log     => [
      '/srv/log/*/auth.log',
      '/srv/log/*/cron.log',
      '/srv/log/*/daemon.log',
      '/srv/log/*/drupal.log',
      '/srv/log/*/mail.log',
      '/srv/log/*/syslog',
      '/srv/log/*/kern.log',
    ].join("\n"),
    options => [
      'rotate 4',
      'daily',
      'missingok',
      'notifempty',
      'compress',
    ],
  }
}
