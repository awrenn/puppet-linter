# == Class: profile::postgres::install_pglogical
#
# A profile class for installing pglogical
# http://2ndquadrant.com/en/resources/pglogical/pglogical-installation-instructions/
#
# === Authors
#
#  Puppet QE <qe-team@puppet.com>
#
# === Copyright
#
# Copyright 2016 Puppet, unless otherwise noted.
#
class profile::postgresql::install_pglogical {

  $pgsql_version = hiera('postgresql::globals::version', undef)
  # pglogical is only available for 9.4 and 9.5
  if ( $pgsql_version and $pgsql_version =~ /9\.[456]/)
  {

    case $facts['os']['name'] {
      'debian': {
        #https://wiki.postgresql.org/wiki/Apt
        apt::source { 'postgresql':
          location => 'http://apt.postgresql.org/pub/repos/apt/',
          release  => "${facts['os']['distro']['codename']}-pgdg",
          repos    => 'main',
        }
        apt::key { 'postgresql-gpg-key':
          id     => 'ACCC4CF8',
          source => 'https://www.postgresql.org/media/keys/ACCC4CF8.asc',
        }


        apt::source { '2ndquadrant-pglogical':
          location => 'http://packages.2ndquadrant.com/pglogical/apt/',
          release  => "${facts['os']['distro']['codename']}-2ndquadrant",
          repos    => 'main',
        }
        apt::key { '2ndquadrant-pglogical-gpg-key':
          id     => 'AA7A6805',
          source => 'http://packages.2ndquadrant.com/pglogical/apt/AA7A6805.asc',
        }

        # Debian package
        package { "postgresql-${pgsql_version}-pglogical":
          ensure  => 'present',
          name    => "postgresql-${pgsql_version}-pglogical",
          require => Apt::Source['postgresql', '2ndquadrant-pglogical'],
        }
      }
      'centos': {
        package { 'plogical repository RPM':
          ensure => 'present',
          name   => 'pglogical-rhel',
          source => 'http://packages.2ndquadrant.com/pglogical/yum-repo-rpms/pglogical-rhel-1.0-3.noarch.rpm',
        }

        #postgresql94-pglogical

        $nodotversion = regsubst($pgsql_version, '\.', '', 'G')
        package { "postgresql${nodotversion}-pglogical":
          ensure  => 'present',
          name    => "postgresql${nodotversion}-pglogical",
          require => Package['plogical repository RPM'],
        }
      }
    }
  }
}
