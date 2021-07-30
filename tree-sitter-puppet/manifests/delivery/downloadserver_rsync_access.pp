class profile::delivery::downloadserver_rsync_access (
  String[1] $ssh_private_key
  ) {

  user { 'rsync':
    ensure         => present,
    managehome     => true,
    gid            => 'release',
    home           => '/home/rsync',
    purge_ssh_keys => true,
  }

  file { '/home/rsync/.ssh':
    ensure  => directory,
    owner   => 'rsync',
    mode    => '0700',
    require => User['rsync'],
  }

  file { '/home/rsync/.ssh/id_rsa':
    ensure  => 'present',
    content => $ssh_private_key,
    owner   => 'rsync',
    mode    => '0600',
    require => [User['rsync'], File['/home/rsync/.ssh']],
  }
}
