class profile::imaging::nfs::packer {
  include nfs::server

  file { '/srv/packer':
    ensure => directory,
  }

  nfs::server::export { '/srv/packer':
    ensure  => 'mounted',
    clients => '10.32.77.0/24(rw,insecure,async,no_root_squash) 10.32.22.0/23(ro,insecure,async,no_root_squash) 10.16.22.0/23(ro,insecure,async,no_root_squash)',
    require => File['/srv/packer'],
  }
}
