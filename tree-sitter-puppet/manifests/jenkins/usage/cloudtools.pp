# Class: profile::jenkins::usage::cloudtools
#
class profile::jenkins::usage::cloudtools {
  include profile::python
  include profile::aws::cli

  package { 'packer':
    ensure => present,
  }
}
