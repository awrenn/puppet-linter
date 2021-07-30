# This kludge configures the appropriate backports repo for
# Wheezy, while also pinning `createrepo` to that backports
# repo. This will result in a newer `createrepo` being
# installed and *that* will make your life better.
# I promise.

class profile::delivery::repository::backports {
  if $facts['os']['name'] == 'Debian' {
    if $facts['os']['release']['major'] == '7' {
      if ! defined(Class['Profile::Apt']) {
        include profile::apt
      }

      include apt::backports

      apt::pin{ 'createrepo-deps':
        packages => 'yum deltarpm python-deltarpm',
        release  => "${facts['os']['distro']['codename']}-backports",
        priority => '1000',
        require  => Class['apt::backports'],
      }
    }
  }
}
