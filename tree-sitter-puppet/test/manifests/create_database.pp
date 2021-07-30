class profile::postgresql::create_database {

  include profile::postgresql::params

  $create_database = $::profile::postgresql::params::create_database
  create_resources('postgresql::server::db', $create_database)

  $create_database.keys.each |$db| {
    ::postgresql::server::database_grant { "${db}_grant_ops_user":
      privilege => 'CONNECT',
      db        => $db,
      role      => 'ops_user',
    }
  }
}

