class profile::server::darwin {

  # let local admins login over ssh and sudo
  ssh::allowgroup  { 'admin': }
  sudo::allowgroup { 'admin': }
}
