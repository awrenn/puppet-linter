class profile::imaging::nfs::puppet {
  include nfs::server

  file { '/srv/puppet':
    ensure => directory,
  }

  nfs::server::export { '/srv/puppet':
    ensure  => 'mounted',
    clients => '10.32.77.0/24(ro,insecure,async,no_root_squash)',
    require => File['/srv/puppet'],
  }
}
