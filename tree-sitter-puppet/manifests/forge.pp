# == Class: profile::forge
#
# Default profile used by all Forge.
#
# === Authors
#
#  Puppet Ops <opsteam@puppetlabs.com>
#
# === Copyright
#
# Copyright 2014 Puppet Labs, unless otherwise noted.
#
class profile::forge {

  include puppetlabs::ssl

  if $facts['networking']['domain'] != 'aws.puppetlabs.com' {
    # not clear whether this is even needed outside of AWS
    include hosts
  }

  include virtual::users

  Account::User <| groups == 'forge-admins' |>
  Group         <| title  == 'forge-admins' |>

  # Allow SSH: forge-admins group
  ssh::allowgroup { 'forge-admins': }

  # Allow full sudo: forge-admins group
  sudo::allowgroup { 'forge-admins': }

  # Performance Tuning: ulimits
  class { 'ulimit':
    purge => false,
  }
  ulimit::rule {
    'soft':
      ulimit_domain => '*',
      ulimit_type   => 'soft',
      ulimit_item   => 'nofile',
      ulimit_value  => '65536';

    'hard':
      ulimit_domain => '*',
      ulimit_type   => 'hard',
      ulimit_item   => 'nofile',
      ulimit_value  => '65536';
  }

  # Extra system tools used in the forge evironments
  $packages = [ 'ccze', 'moreutils', 'mailutils' ]
  package { $packages: ensure => latest }

  package { 'bundler':
    ensure   => '1.17.3',
    provider => 'gem',
  }

  # Install Glances form pip
  package { 'Glances':
    ensure   => installed,
    provider => pip,
    require  => Package['python-dev'],
  }
}
