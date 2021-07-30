class profile::delivery::apt_signing_server::puppet6_nightly {

  file { '/opt/freight/puppet_6_nightly':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'release',
    mode    => '02775',
    require => File['/opt/freight'],
  }

  freight::repo { 'puppet_6_nightly':
    freight_libdir           => '/opt/freight/puppet_6_nightly/lib',
    freight_docroot          => '/opt/freight/puppet_6_nightly/cache',
    freight_gpgkey           => '4528B6CD9E61EF26',
    freight_group            => 'release',

    freight_manage_libdir    => true,
    freight_manage_docroot   => false,
    freight_manage_vhost     => false,
    freight_manage_ssl_vhost => false,
    freight_redirect         => false,
    freight_symlinks         => 'on',
  }
}
