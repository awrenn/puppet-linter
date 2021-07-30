# Class: profile::mongodb::server
#
class profile::mongodb::server {
  require ::profile::mongodb::globals
  include profile::mongodb::params

  validate_array($::profile::mongodb::params::bind_ip)

  class { '::mongodb::server':
    bind_ip => $::profile::mongodb::params::bind_ip,
  }
}
