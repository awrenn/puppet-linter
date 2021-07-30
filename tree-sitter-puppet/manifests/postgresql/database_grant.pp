class profile::postgresql::database_grant {

  $database_grant = $::profile::postgresql::params::database_grant
  create_resources('postgresql::server::database_grant', $database_grant)

}
