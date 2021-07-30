class profile::active_directory::create_user {
  include profile::active_directory::params

  $create_user = $::profile::active_directory::params::create_user
  if $create_user {
    create_resources('windows_ad::user', $create_user)
  }
}
