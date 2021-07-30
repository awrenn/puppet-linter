class profile::postgresql::backup_db {

  include profile::postgresql::params

  $backup_db = $::profile::postgresql::params::backup_db
  if $backup_db {
    create_resources('profile::backup::postgresql_db', $backup_db)
  }
}
