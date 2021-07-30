# Class: profile::mongodb::client
#
class profile::mongodb::client {
  require ::profile::mongodb::globals
  include profile::mongodb::params

  class { '::mongodb::client': }
}
