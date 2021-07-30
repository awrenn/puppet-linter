class profile::postgresql::authorized_keys {

  $authorized_keys = $::profile::postgresql::params::authorized_keys
  if $authorized_keys {
    create_resources('ssh_authorized_key', $authorized_keys)

    ssh::allowgroup { 'postgres': }
  }

}
