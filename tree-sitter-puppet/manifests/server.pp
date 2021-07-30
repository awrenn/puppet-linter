# Class: profile::server
#
class profile::server {
  include profile::server::params

  $metrics    = $profile::server::params::metrics
  $backups    = $profile::server::params::backups
  $monitoring = $profile::server::params::monitoring
  $logging    = $profile::server::params::logging
  $promtail   = $profile::server::params::promtail
  $fluentd    = $profile::server::params::fluentd
  $fw         = $profile::server::params::fw
  $fw_purge   = $profile::server::params::fw_purge

  if $facts['kernel'] == 'windows' {
    include profile::server::windows
  } else {
    include profile::server::splatnix
  }
}
