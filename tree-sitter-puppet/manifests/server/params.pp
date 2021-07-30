##
#
class profile::server::params {
  $metrics    = hiera('profile::server::metrics', false)
  $backups    = hiera('profile::server::backups', false)
  $monitoring = hiera('profile::server::monitoring', false)
  $logging    = hiera('profile::server::logging', false)
  $promtail   = hiera('profile::server::promtail', false)
  $fluentd    = hiera('profile::server::fluentd', false)
  $fw         = hiera('profile::server::fw', false)
  $fw_purge   = hiera('profile::server::fw_purge', false)
}
