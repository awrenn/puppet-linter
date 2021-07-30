class profile::repo::ips(
  $base_dir      = '/export/repository',
  $publishers    = ['solaris', 'solarisstudio'],
  $cron_schedule = '30 0,12 * * *',
  $debug         = false
) inherits profile::os::solaris {

  Pkg_publisher['solaris'] {
    origin  => 'https://pkg.oracle.com/solaris/support',
    sslcert => $profile::os::solaris::oracle_certs::support_cert_file,
    sslkey  => $profile::os::solaris::oracle_certs::support_key_file,
    require => File[[
      $profile::os::solaris::oracle_certs::support_cert_file,
      $profile::os::solaris::oracle_certs::support_key_file,
    ]]
  }

  Pkg_publisher['solarisstudio'] {
    origin  => 'https://pkg.oracle.com/solarisstudio/release',
    sslcert => $profile::os::solaris::oracle_certs::studio_release_cert_file,
    sslkey  => $profile::os::solaris::oracle_certs::studio_release_key_file,
    require => File[[
      $profile::os::solaris::oracle_certs::studio_release_cert_file,
      $profile::os::solaris::oracle_certs::studio_release_key_file,
    ]]
  }

  file { '/lib/svc/manifest/application/pkg/pkg-mirror.xml':
    content => template('profile/repo/pkg-mirror.xml.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'sys',
    notify  => Service['system/manifest-import:default'],
  }

  file { '/lib/svc/manifest/application/pkg/pkg-server.xml':
    content => template('profile/repo/pkg-server.xml.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'sys',
    notify  => Service['system/manifest-import:default'],
  }

  service { 'application/pkg/server:default':
    ensure    => running,
    enable    => true,
    subscribe => [
      Service['system/manifest-import:default'],
      File['/lib/svc/manifest/application/pkg/pkg-server.xml']
    ],
  }

  service { 'application/pkg/mirror:default':
    ensure    => running,
    enable    => true,
    require   => Pkg_publisher[['solaris', 'solarisstudio']],
    subscribe => [
      Service['system/manifest-import:default'],
      File['/lib/svc/manifest/application/pkg/pkg-mirror.xml']
    ],
  }
}
