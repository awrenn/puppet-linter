class profile::delivery::apt_signing_server {
  profile_metadata::service { $title:
    human_name        => 'Apt signing server',
    team              => 're',
    owner_uid         => 'eric.griswold',
    end_users         => ['pe-and-platform-program@puppet.com'],
    escalation_period => 'pdx-workhours',
    downtime_impact   => @(END),
      Package build and shipping pipelines will fail.
      | END
  }

  case $facts['os']['family'] {
    'debian': {
      include freight

      apt::key { 'puppetlabs gpg key':
        id     => '47B320EB4C7C375AA9DAE1A01054B7A24BD6EC30',
        source => 'http://pl-build-tools.delivery.puppetlabs.net/debian/DEB-GPG-KEY-puppetlabs',
      }

      apt::key { 'puppet gpg key 2025-04-06':
        id     => 'D6811ED3ADEEB8441AF5AA8F4528B6CD9E61EF26',
        source => 'http://pl-build-tools.delivery.puppetlabs.net/debian/DEB-GPG-KEY-puppet-20250406',
      }

      # Repository document root, if the repos are served
      file { '/opt/repository':
        ensure => directory,
        owner  => 'root',
        group  => 'release',
        mode   => '02775',
      }

      # Freight working directories, where files are stored for indexing

      # /opt/tools freight directories are obsolescent in favor of /opt/freight
      file { '/opt/tools':
        ensure => directory,
        group  => 'release',
        mode   => '0775',
      }

      # This version indexes and stages together
      file { '/opt/freight':
        ensure => directory,
        group  => 'release',
        mode   => '0775',
      }
    }

    default: { notify { "OS ${facts['os']['family']} has no love and signs no apt repos!": } }
  }
}
