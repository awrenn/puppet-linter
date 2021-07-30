# == Class: profile::statsd
#
# A profile class for statsd
#
# === Authors
#
#  Puppet Ops <opsteam@puppetlabs.com>
#
# === Copyright
#
# Copyright 2013 Puppet Labs, unless otherwise noted.
#
class profile::statsd {

  $graphiteserver   = hiera('profile::statsd::graphiteserver','localhost')
  $graphiteport     = hiera('profile::statsd::graphiteport','2003')
  $address          = hiera('profile::statsd::address','0.0.0.0')
  $listenport       = hiera('profile::statsd::listenport','8125')
  $flushinterval    = hiera('profile::statsd::flushinterval','10000')
  $percentthreshold = hiera('profile::statsd::percentthreshold',['90'])
  $ensure           = hiera('profile::statsd::ensure','present')
  $provider         = hiera('profile::statsd::provider','npm')
  $legacy_namespace  = hiera('profile::statds::graphite_legacyNamespace', 'true')
  $global_prefix     = hiera('profile::statsd::graphite_globalPrefix', 'stats')
  $prefix_counter    = hiera('profile::statsd::graphite_prefixCounter', 'counters')
  $prefix_timer      = hiera('profile::statsd::graphite_prefixTimer', 'timers')
  $prefix_gauge      = hiera('profile::statsd::graphite_prefixGauge', 'gauges')
  $prefix_set        = hiera('profile::statsd::graphite_prefixSet', 'sets')
  $init_provider    = hiera('profile::statsd::init_provider', 'debian')
  $init_location    = hiera('profile::statsd::init_location', '/etc/init.d/statsd')
  $init_mode        = hiera('profile::statsd::init_mode', '0755')

  meta_motd::register { 'statsd Profile': }

  class { '::profile::nodejs':
    package_version => 'latest',
  }

  package { ['nodejs-legacy', 'forge-npm']:
    ensure        => absent,
    allow_virtual => false,
  }

  class { '::statsd':
    graphiteHost             => $graphiteserver,
    graphitePort             => $graphiteport,
    address                  => $address,
    port                     => $listenport,
    flushInterval            => $flushinterval,
    percentThreshold         => $percentthreshold,
    ensure                   => $ensure,
    package_provider         => $provider,
    init_script              => 'puppet:///modules/profile/statsd/statsd-init',
    init_provider            => $init_provider,
    init_location            => $init_location,
    init_mode                => $init_mode,
    graphite_legacyNamespace => $legacy_namespace,
    graphite_globalPrefix    => $global_prefix,
    graphite_prefixCounter   => $prefix_counter,
    graphite_prefixTimer     => $prefix_timer,
    graphite_prefixGauge     => $prefix_gauge,
    graphite_prefixSet       => $prefix_set,
  }

  contain ::statsd

  Class['::profile::nodejs'] -> Class['::statsd']

  # Setup additional firewall rules.
  # Note: the following rules are in addtion to the default rules
  # found on a base instance.
  if $::profile::server::params::fw {
    firewall {'100 allow inbound statsd traffic':
      dport  => [ $listenport ],
      proto  => 'udp',
      action => 'accept',
    }
  }
}
