class profile::delivery::apt_signing_server::community {
  freight::repo { 'community':
    freight_vhost_name       => 'apt.puppetlabs.com',
    freight_docroot          => '/opt/repository/apt',
    freight_gpgkey           => '4528B6CD9E61EF26',
    freight_group            => 'release',
    freight_libdir           => '/opt/tools/freight',
    freight_manage_libdir    => true,
    freight_manage_docroot   => false,
    freight_manage_vhost     => false,
    freight_manage_ssl_vhost => false,
    freight_redirect         => false,
    freight_symlinks         => 'on',
    require                  => File['/opt/tools'],
  }
}
