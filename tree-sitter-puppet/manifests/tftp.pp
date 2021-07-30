class profile::tftp {

  # Picking static site specific things so that this is the same no matter
  # the platform we deploy to.
  class { '::tftp':
    directory => '/srv/tftp',
    username  => 'nobody',
  }
  file { '/srv/tftp':
    ensure => directory,
    mode   => '0660',
    owner  => 'nobody',
    group  => 'root',
  }
}
