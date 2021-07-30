# == Class: profile::haproxy::metrics
#
# HAProxy Metrics Profile
#
# === Authors
#
#  Puppet Ops <opsteam@puppetlabs.com>
#
# === Copyright
#
# Copyright 2014 Puppet Labs, unless otherwise noted.
#
class profile::haproxy::metrics (
  Optional[Integer] $interval = undef,
  Optional[Boolean] $prometheus = false,
) {

  unless $facts["whereami"] == 'aws_internal_net_vpc' {
    include profile::metrics::diamond::client
    include profile::metrics::diamond::collectors

    $raw_collector_options = {
      'url' => 'http://localhost:7070/haproxy?stats;csv',
      'interval' => $interval,
    }

    $collector_options = $raw_collector_options.filter |$key, $val| { $val =~ NotUndef }

    Diamond::Collector <| title == 'HAProxyCollector' |> {
      options => $collector_options,
    }
  }

  $stats_options_base = {
    'mode'  => 'http',
    'stats' => ['uri /'],
  }

  if $prometheus {
    # makes prometheus compatible stats available at http://127.0.0.1:7070/metrics
    $stats_options = $stats_options_base + {
      'http-request' => 'use-service prometheus-exporter if { path /metrics }',
    }

    if $profile::metrics::enable_prometheus {
      telegraf::input { 'haproxy-prometheus':
        plugin_type => 'prometheus',
        options     => [
          alias     => 'haproxy',
          urls      => ['http://localhost:7070/metrics'],
        ],
      }
    }
  } else {
    $stats_options = $stats_options_base
  }

  haproxy::listen { 'stats':
    ipaddress        => '127.0.0.1',
    ports            => ['7070'],
    collect_exported => false,
    options          => $stats_options,
  }
}
