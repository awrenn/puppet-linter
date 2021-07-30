class profile::release::prime_gpg {
  package { 'pinentry-curses':
    ensure => installed,
  }

  file { '/usr/local/bin/prime_gpg':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/profile/release/prime_gpg',
  }
}
