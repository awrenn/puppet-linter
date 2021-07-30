class profile::active_directory::create_ou {
  include profile::active_directory::params

  $create_ou = $::profile::active_directory::params::create_ou
  if $create_ou {
    create_resources('windows_ad::organisationalunit', $create_ou)
  }
}
