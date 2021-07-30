# Install the packages needed to use Software Collections on CentOS
class profile::os::linux::redhat::scl_repos {
  package { 'centos-release-scl':
    ensure => present,
  }

  package { 'centos-release-scl-rh':
    ensure => present,
  }

  exec { 'make scl repo cache':
    command     => '/usr/bin/yum makecache',
    subscribe   => Package[
      'centos-release-scl',
      'centos-release-scl-rh',
    ],
    refreshonly => true,
  }
}
