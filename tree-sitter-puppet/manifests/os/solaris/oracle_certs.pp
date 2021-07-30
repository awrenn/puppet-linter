#3
#
class profile::os::solaris::oracle_certs {

  $pkg_ssl_dir              = '/var/pkg/ssl'
  $support_cert_file        = "${pkg_ssl_dir}/Oracle_Solaris_11_Support.certificate.pem"
  $support_key_file         = "${pkg_ssl_dir}/Oracle_Solaris_11_Support.key.pem"
  $studio_release_cert_file = "${pkg_ssl_dir}/Oracle_Solaris_Studio_Release.certificate.pem"
  $studio_release_key_file  = "${pkg_ssl_dir}/Oracle_Solaris_Studio_Release.key.pem"
  $support_cert             = hiera('profile::os::solaris::oracle_certs::support_cert')
  $support_key              = hiera('profile::os::solaris::oracle_certs::support_key')
  $studio_release_cert      = hiera('profile::os::solaris::oracle_certs::support_cert')
  $studio_release_key       = hiera('profile::os::solaris::oracle_certs::support_key')

  File {
    mode    => '0640',
    owner   => 'root',
    group   => 'pkg5srv',
  }

  file { $pkg_ssl_dir:
    ensure  => directory,
    recurse => true,
  }

  file { 'Oracle_Solaris_11_Support.certificate.pem':
    path    => $support_cert_file,
    content => $support_cert,
  }
  file { 'Oracle_Solaris_11_Support.key.pem':
    path    => $support_key_file,
    content => $support_key,
  }
  file { 'Oracle_Solaris_Studio_Release.certificate.pem':
    path    => $studio_release_cert_file,
    content => $studio_release_cert,
  }
  file { 'Oracle_Solaris_Studio_Release.key.pem':
    path    => $studio_release_key_file,
    content => $studio_release_key,
  }
}
