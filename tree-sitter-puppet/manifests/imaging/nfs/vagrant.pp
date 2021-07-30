class profile::imaging::nfs::vagrant {
  include nfs::server

  file { '/srv/vagrant':
    ensure => directory,
  }

  nfs::server::export { '/srv/vagrant':
    ensure  => 'mounted',
    clients => '10.32.77.0/24(rw,insecure,async,no_root_squash)',
    require => File['/srv/vagrant'],
  }
}
