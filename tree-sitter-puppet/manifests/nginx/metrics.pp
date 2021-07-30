# == Class: profile::nginx::metrics
#
# Nginx Metrics Profile
#
# === Authors
#
#  Puppet Ops <opsteam@puppetlabs.com>
#
# === Copyright
#
# Copyright 2014 Puppet Labs, unless otherwise noted.
#
class profile::nginx::metrics (
  Optional[Integer] $interval = undef,
) {
  include profile::nginx
  include profile::metrics::diamond::client
  include profile::metrics::diamond::collectors

  nginx::resource::server { 'status':
    ensure               => 'present',
    server_name          => ['status'],
    listen_port          => 70,
    listen_ip            => '127.0.0.1',
    listen_options       => 'default',
    ssl                  => false,
    use_default_location => false,
    access_log           => 'off',
    error_log            => '/var/log/nginx/status.error.log',
  }

  nginx::resource::location { '/nginx_status':
    ensure              => 'present',
    stub_status         => true,
    location_custom_cfg => {
      allow => '127.0.0.1',
      deny  => 'all',
    },
    server              => 'status',
  }

  $raw_collector_options = {
    'req_port' => 70,
    'interval' => $interval,
  }

  $collector_options = $raw_collector_options.filter |$key, $val| { $val =~ NotUndef }

  Diamond::Collector <| title == 'NginxCollector' |> {
    options => $collector_options,
  }
}
