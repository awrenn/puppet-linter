class profile::release::apt_scripts {
  file { '/usr/local/bin/freight-cache-wrapper':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/profile/release/freight-cache-wrapper',
  }
}
