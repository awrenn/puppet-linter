class profile::active_directory::params {
  $create_ou   = hiera('profile::active_directory::create_ou', false)
  $create_user = hiera('profile::active_directory::create_user', false)
}
