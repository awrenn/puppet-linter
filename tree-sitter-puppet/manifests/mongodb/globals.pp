# Class: profile::mongodb::globals
#
class profile::mongodb::globals {
  include profile::mongodb::params

  validate_bool($::profile::mongodb::params::manage_package_repo)

  class { '::mongodb::globals':
    manage_package_repo => $::profile::mongodb::params::manage_package_repo,
    version             => $::profile::mongodb::params::version,
  }
}
