class profile::graphite::carbon_c_relay (
  $batch_size           = 2500,
  $queue_size           = 25000,
  $carbon_c_relay_dest  = undef,
  $local                = false,
  $version              = present,
  ) {

  unless $carbon_c_relay_dest { fail('Carbon-c-relay destination needs to be set.') }

  include profile::graphite::prometheus_exporter

  package { 'carbon-c-relay':
    ensure => $version,
  }
  -> file { '/etc/carbon-c-relay.conf':
    ensure  => file,
    content => template('profile/graphite/carbon-c-relay.conf.erb'),
  }
  -> file { '/etc/default/carbon-c-relay':
    ensure  => file,
    content => template('profile/graphite/carbon-c-relay.default.erb'),
  }
  -> file { '/etc/init.d/carbon-c-relay':
    ensure  => file,
    content => template('profile/graphite/carbon-c-relay.erb'),
  }
  -> file { '/var/log/carbon-c-relay.log':
    ensure => file,
    mode   => '0666',
  }
  -> service { 'carbon-c-relay':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/carbon-c-relay.conf'],
  }

  if $::profile::server::monitoring {
    include profile::graphite::monitor::carbon_c_relay
  }
}
