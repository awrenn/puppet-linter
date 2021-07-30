# == Class: profile::postgres::install_devtools
#
# A profile class for installing postgres develeopment tools
#
# === Authors
#
#  Puppet Ops <opsteam@puppetlabs.com>
#
# === Copyright
#
# Copyright 2014 Puppet Labs, unless otherwise noted.
#
class profile::postgresql::install_devtools {

  # Postgres dev tools
  package { 'postgresql-devtools':
    ensure => 'present',
    name   => 'libpq-dev',
  }
}
