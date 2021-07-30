class profile::delivery::apt_signing_server::archive {
  freight::repo { 'archive':
    freight_docroot          => '/opt/release-archives-staging/apt',
    freight_gpgkey           => '4528B6CD9E61EF26',
    freight_group            => 'release',
    freight_libdir           => '/opt/tools/freight-archives',
    freight_manage_libdir    => true,
    freight_manage_docroot   => false,
    freight_manage_vhost     => false,
    freight_manage_ssl_vhost => false,
    freight_redirect         => false,
    freight_symlinks         => 'on',
    require                  => File['/opt/tools'],
  }
}
