class profile::postgresql::create_role {

  $create_role = $::profile::postgresql::params::create_role
  create_resources('postgresql::server::role', $create_role)

}
