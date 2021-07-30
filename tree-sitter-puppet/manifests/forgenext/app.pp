# shared code between web and API app servers
class profile::forgenext::app {
  include profile::forgenext::apt_postgres

  # Since the postgresql::client class only directly manages
  # postgresql-client, it has trouble upgrading in a way that
  # allows apt to resolve dependencies. So instead we'll just
  # manage the relevant packages directly on these hosts.
  apt::pin { 'postgresql-client-common':
    ensure   => present,
    packages => [
      'postgresql-client-common',
      'libpq5',
      'postgresql-client',
    ],
    release  => "${facts['os']['distro']['codename']}-pgdg",
    priority => '999',
    require  => Class['profile::forgenext::apt_postgres'],
  }

  package { ['libpq5', 'postgresql-client']:
    ensure  => latest,
    require => Apt::Pin['postgresql-client-common'],
  }

  # the forge-api and forge-web applications run under rbenv
  class { 'profile::forgenext::rbenv':
    ruby_versions => ['2.6.3'],
  }

  rbenv::gem { 'bundler-2.0.2-on-2.6.3':
    gem          => 'bundler',
    ruby_version => '2.6.3',
    skip_docs    => true,
    version      => '2.0.2',
    require      => Class['profile::forgenext::rbenv'],
  }

  rbenv::gem { 'bundler-2.1.4-on-2.6.3':
    gem          => 'bundler',
    ruby_version => '2.6.3',
    skip_docs    => true,
    version      => '2.1.4',
    require      => Class['profile::forgenext::rbenv'],
  }

  # create /var/nginx since the buster package doesn't create it anymore
  if Integer($facts['os']['release']['major']) >= 10 {
    file { '/var/nginx':
      ensure => 'directory',
      before => Class['profile::nginx'],
    }
  }

  # override nginx systemd unit ExecReload and ExecStop commands
  systemd::dropin_file { 'nginx command overrides':
    filename => '10-reload_and_stop.conf',
    unit     => 'nginx.service',
    source   => 'puppet:///modules/profile/forgenext/app/nginx_reload_stop_dropin.conf',
    notify   => Class['Nginx::Service'],
  }

  # Rotation job for pip logs
  logrotate::job { 'pip':
    log     => '/tmp/pip.log',
    options => [
      'maxsize 100M',
      'rotate 5',
      'weekly',
      'compress',
      'compresscmd /usr/bin/xz',
      'uncompresscmd /usr/bin/unxz',
      'compressext .xz',
      'missingok',
      'notifempty',
      'su root root',
      'create 0644 root root',
    ],
  }

  if $profile::server::metrics {
    include profile::metrics::diamond::client
    include profile::metrics::diamond::collectors
  }

  if $profile::server::fw {
    include profile::fw::http
    include profile::fw::https
    firewall { '103 allow http on 8080':
      dport  => '8080',
      source => '10.0.0.0/8',
      proto  => 'tcp',
      action => 'accept',
    }
  }

  if $profile::server::logging {
    if Integer($facts['os']['release']['major']) < 10 {
      # Restart logstash-forwarder to prevent it from holding open deleted log files.
      # This should be happening automatically, but may not be when the logstash hosts
      # are unavailable.
      cron { 'restart logstash-forwarder':
        ensure  => present,
        command => '/bin/systemctl restart logstash-forwarder.service',
        user    => 'root',
        hour    => 10,
        minute  => 0,
        require => Service['logstash-forwarder'],
      }

      logstashforwarder::file { 'forge_nginx_access':
        paths  => [ '/var/log/nginx/*.access.log' ],
        fields => { 'type' => 'nginx_access_json' },
      }

      logstashforwarder::file { 'forge_nginx_error':
        paths  => [ '/var/log/nginx/*.error.log' ],
        fields => { 'type' => 'nginx_error' },
      }
    }

    include profile::aws::cloudwatch

    $nginx_access_date_format = '%d/%b/%Y:%H:%M:%S %z'
    $nginx_error_date_format = '%Y/%m/%d %H:%M:%S'

    cloudwatch::log {'/var/log/nginx/forge-api.access.combined.log':
      datetime_format => $nginx_access_date_format,
    }

    cloudwatch::log {'/var/log/nginx/forge-web.access.combined.log':
      datetime_format => $nginx_access_date_format,
    }

    cloudwatch::log {'/var/log/nginx/forge-web-react.access.combined.log':
      datetime_format => $nginx_access_date_format,
    }

    cloudwatch::log {'/var/log/nginx/forge-api.error.log':
      datetime_format => $nginx_error_date_format,
    }

    cloudwatch::log {'/var/log/nginx/forge-web.error.log':
      datetime_format => $nginx_error_date_format,
    }

    cloudwatch::log {'/var/log/nginx/forge-web-react.error.log':
      datetime_format => $nginx_error_date_format,
    }
  }
}
