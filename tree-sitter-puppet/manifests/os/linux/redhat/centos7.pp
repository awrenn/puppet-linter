# Configuration specific to CentOS 7.
class profile::os::linux::redhat::centos7 (
  Boolean $enable_networkmanager = false,
) {
  include profile::repo::params

  if $enable_networkmanager {
    package { 'NetworkManager':
      ensure => latest,
      notify => Service['NetworkManager'],
    }
    service { 'NetworkManager':
      ensure => running,
      enable => true,
    }
  } else {
    service { 'NetworkManager':
      ensure => stopped,
      enable => false,
    }
  }

  unless $facts["whereami"] == 'aws_internal_net_vpc' {
    yumrepo { 'sysops-checks':
      descr    => 'Puppet Labs Sysops Nagios/Icinga checks',
      proxy    =>  absent,
      baseurl  => 'https://artifactory.delivery.puppetlabs.net/artifactory/rpm__local_infracore/sysops-checks/7/x86_64',
      enabled  => 1,
      gpgcheck => 0,
    }
  }
}
