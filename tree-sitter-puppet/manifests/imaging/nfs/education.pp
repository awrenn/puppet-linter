class profile::imaging::nfs::education {
  include nfs::server

  file { '/srv/education':
    ensure => directory,
  }

  nfs::server::export { '/srv/education':
    ensure  => 'mounted',
    clients => '10.32.77.0/24(rw,insecure,async,no_root_squash)',
    require => File['/srv/education'],
  }
}
