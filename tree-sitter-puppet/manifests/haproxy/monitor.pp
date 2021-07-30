# == Class: profile::haproxy::monitor
#
# HAProxy Monitoring Profile
#
# === Authors
#
#  Puppet Ops <opsteam@puppetlabs.com>
#
# === Copyright
#
# Copyright 2016 Puppet Labs, unless otherwise noted.
#
class profile::haproxy::monitor {
  include profile::erlang

  # haproxy backend server count check is installed as rpm/deb
  # see https://github.com/danieldreier/haproxy_stats_check for source,
  # readme, and build/usage instructions
  if $facts['os']['family'] == 'RedHat' {
    # the RPM ended up called haproxy_check. I can fix this if people think
    # it's important enough
    package { 'haproxy_check':
      ensure  => latest,
      require => Yumrepo['sysops-checks'],
    }
    # if you need to put a newer version of haproxy_check in that repo:
    # * build using instructions from
    #   https://github.com/danieldreier/haproxy_stats_check
    # * scp the resulting RPM to the repo server above and put the rpm in
    #   /opt/repos/sysops-checks/7/x86_64/
    # * then touch /opt/repos/sysops-checks/7/x86_64/.rebuild and re-run puppet
  } elsif $facts['os']['name'] == 'Debian' {
    if (Integer($facts['os']['release']['major']) < 10) {
      package { 'haproxy-check':
        ensure => latest,
      }
    }
  }
}
