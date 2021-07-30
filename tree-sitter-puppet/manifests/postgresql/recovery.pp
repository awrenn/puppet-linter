class profile::postgresql::recovery {

  $master_url = $::profile::postgresql::params::master_url

  file { 'archive_dir':
    ensure => 'directory',
    path   => '/var/lib/postgresql/9.3/archive',
    owner  => 'postgres',
    group  => 'postgres',
    mode   => '0700',
  }

  -> file { 'recovery.conf':
    ensure  => 'file',
    path    => '/var/lib/postgresql/9.3/main/recovery.conf',
    content => template('profile/postgresql/recovery.conf.erb'),
    owner   => 'postgres',
    group   => 'postgres',
  }
}
