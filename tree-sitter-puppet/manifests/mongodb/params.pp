# Class: profile::mongodb::params
#
class profile::mongodb::params {
  $bind_ip             = hiera('profile::mongodb::bind_ip', ['0.0.0.0'])
  $db                  = hiera('profile::mongodb::db', false)
  $manage_package_repo = hiera('profile::mongodb::manage_package_repo', true)
  $version             = hiera('profile::mongodb::version', undef)
}
