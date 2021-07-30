# This class is responsible for managing CentOS-specific configuration.
class profile::os::linux::redhat::centos (
  String[1] $base_mirrorlist,
  String[1] $updates_mirrorlist,
  String[1] $extras_mirrorlist,
  String[1] $centosplus_mirrorlist,
  String[1] $base_baseurl          = absent,
  String[1] $updates_baseurl       = absent,
  String[1] $extras_baseurl        = absent,
  String[1] $centosplus_baseurl    = absent,
) {
  include profile::os::linux::redhat::el
  include profile::os::linux::redhat::autoupdates
  include profile::repo::params

  $major = $facts['os']['release']['major']
  $arch = $facts['os']['architecture']

  file { '/etc/cron.daily/0logwatch':
    ensure => absent,
  }

  yumrepo {
    default:
      proxy    => $profile::repo::params::proxy_url,
      gpgkey   => "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-${major}",
      enabled  => 1,
      gpgcheck => 1,
    ;
    'base':
      descr      => 'CentOS-$releasever - Base',
      mirrorlist => $base_mirrorlist,
      baseurl    => $base_baseurl,
    ;
    'updates':
      descr      => 'CentOS-$releasever - Updates',
      mirrorlist => $updates_mirrorlist,
      baseurl    => $updates_baseurl,
    ;
    'extras':
      descr      => 'CentOS-$releasever - Extras',
      mirrorlist => $extras_mirrorlist,
      baseurl    => $extras_baseurl,
    ;
    'centosplus':
      descr      => 'CentOS-$releasever - Plus',
      mirrorlist => $centosplus_mirrorlist,
      baseurl    => $centosplus_baseurl,
    ;
  }

  unless $facts["whereami"] == 'aws_internal_net_vpc' or $major == '6' {
    yumrepo { 'sysops-diamond':
      baseurl  => "https://artifactory.delivery.puppetlabs.net/artifactory/rpm__local_infracore/sysops-diamond/${major}/${arch}",
      descr    => 'Puppet Labs Diamond Repository',
      proxy    => absent,
      enabled  => 1,
      gpgcheck => 0,
    }
  }

  if $major == '7' {
    include profile::os::linux::redhat::centos7
  } elsif $major == '6' {
    include profile::os::linux::redhat::centos6
  } else {
    fail("profile::os::linux::redhat::centos doesn't support CentOS ${major}")
  }
}
