class profile::postgresql::create_database_with_grant {

  define profile::postgresql::create_database_with_grant (
    $owner,
  ){

    postgresql::server::database { $title:
      owner => $owner,
    }

    postgresql::server::database_grant { $title:
      privilege => 'ALL',
      db        => $title,
      role      => $owner,
    }
  }

  $create_database_with_grant = $::profile::postgresql::params::create_database_with_grant
  create_resources('profile::postgresql::create_database_with_grant', $create_database_with_grant)

}
