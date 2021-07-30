# Class: profile::jenkins::usage::postgresql
# A usage profile to manage the PostgreSQL client
#
class profile::jenkins::usage::postgresql {
  class { '::postgresql::globals':
    manage_package_repo => true,
    version             => '9.4',
  }

  include postgresql::client

  # These packages are required for the ruby gem "pg"
  # lint:ignore:selector_inside_resource
  package { 'libpq libs':
    ensure => $facts['os']['name'] ? {
      /(?i)(debian|ubuntu)/             => present,
      /(?i)(centos|fedora|redhat|sles)/ => present,
      default                           => absent,
    },
    name   => $facts['os']['name'] ? {
      /(?i)(debian|ubuntu)/             => 'libpq-dev',
      /(?i)(centos|fedora|redhat|sles)/ => 'postgresql-devel',
      default                           => undef,
    },
  }
  # lint:endignore
}
