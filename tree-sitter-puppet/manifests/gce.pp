# == Class: profile::gce
#
# Profile class for GCE Instances.
#
# === Authors
#
#  Puppet Ops <opsteam@puppetlabs.com>
#
# === Copyright
#
# Copyright 2013 Puppet Labs, unless otherwise noted.
#
class profile::gce {

  file { '/etc/hostname':
    ensure  => present,
    content => "${trusted['certname']}\n",
  }
  -> exec { 'Update hostname':
    command => '/etc/init.d/hostname.sh',
  }

  file { '/etc/rc.local':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0775',
    source => 'puppet:///modules/profile/gce/gce-rc.local',
  }
}
