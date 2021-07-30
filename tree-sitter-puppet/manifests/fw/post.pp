class profile::fw::post {
  firewall { '999 drop all':
    proto  => 'all',
    action => 'drop',
    before => undef,
  }

  firewall { '999 drop all v6':
    proto    => 'all',
    action   => 'drop',
    before   => undef,
    provider => 'ip6tables',
  }
}
