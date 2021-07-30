class profile::postgresql::params {

  $password_hash              = hiera('profile::postgresql::password_hash', false)

  $create_database            = hiera('profile::postgresql::create_database', false)
  $create_database_with_grant = hiera('profile::postgresql::create_database_with_grant', false)

  $create_role                = hiera('profile::postgresql::create_role', false)
  $database_grant             = hiera('profile::postgresql::database_grant', false)

  $pg_hba_rules               = hiera('profile::postgresql::pg_hba_rules', false)

  $master_url                 = hiera('profile::postgresql::master_url', false)
  $slave_url                  = hiera('profile::postgresql::slave_url', false)

  $log_destination            = hiera('profile::postgresql::configuration::log_destination', false)
  $logging_collector          = hiera('profile::postgresql::configuration::logging_collector', false)
  $log_min_duration_statement = hiera('profile::postgresql::configuration::log_min_duration_statement', 1000)
  $log_line_prefix            = hiera('profile::postgresql::configuration::log_line_prefix',
                                      '%m [db:%d,user:%s,sess:%c,pid:%p,vtid:%v,tid:%x] ')

  $authorized_keys            = hiera('profile::postgresql::authorized_keys', false)
  $replication_master         = hiera('profile::postgresql::configuration::replication_master', false)
  $replication_slave          = hiera('profile::postgresql::configuration::replication_slave', false)
  $addslave                   = hiera('profile::postgresql::configuration::addslave', false)
  $manage_logging             = hiera('profile::postgresql::configuration::manage_logging', false)
  $backup_db                  = hiera('profile::postgresql::backup_db', false)

  $max_connections            = hiera('profile::postgresql::max_connections', false)
  $pglogical_replication      = hiera('profile::postgresql::configuration::pglogical_replication', false)
}
