# Class: profile::mesos::master::marathon
#
class profile::mesos::master::marathon (
  $version = installed,
  $graphite_url = undef,
  $graphite_port = 2003,
  $metrics_interval = 60,
  $marathon_prefix = undef,
  $disable_timing_metrics = true
) {

  meta_motd::register { 'Marathon (profile::mesos::master::marathon)': }

  file { ['/etc/marathon', '/etc/marathon/conf']:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0400',
  }

  if $graphite_url {
    unless $marathon_prefix {
      fail('$marathon_prefix is required when shipping marathon metrics to graphite')
    }
    if versioncmp($version, '1.4') == 1 { # starting at version 1.5.x breaking change to passing options https://github.com/mesosphere/marathon/blob/master/changelog.md#changes-from-14x-to-150
      notify { 'version >= 1.5':
        message => 'options are now passed in /etc/default/marathon',
      }
      file_line {'marathon_config_enable_graphite':
        path    => '/etc/default/marathon',
        line    => "MARATHON_REPORTER_GRAPHITE=\"tcp://${graphite_url}:${graphite_port}?prefix=stats.${marathon_prefix}.marathon&interval=${metrics_interval}\"",
        require => Package['marathon'],
      }

      file_line {'marathon_config_disable_metrics':
        path    => '/etc/default/marathon',
        line    => 'MARATHON_DISABLE_METRICS=',
        require => Package['marathon'],
      }
    } else {
      # Configuration options for marathon
      # Documentation for marathon describes command line flags available https://mesosphere.github.io/marathon/docs/command-line-flags
      # These flags can be set as files in the /etc/marathon/conf directory
      # Each file is equivalent to a command line option with its contents as the value
      file { '/etc/marathon/conf/reporter_graphite':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => "tcp://${graphite_url}:${graphite_port}?prefix=stats.${marathon_prefix}.marathon&interval=${metrics_interval}",
        notify  => Service['marathon'],
      }

      # From the docs about metrics
      # (Optional. Default: enabled): Expose the execution time per method via the metrics endpoint (/metrics)
      # using code instrumentation. Enabling this might noticeably degrade performance but it helps finding
      # performance problems. These measurements can be disabled with –disable_metrics. Other metrics are not affected.
      if $disable_timing_metrics {
        file { '/etc/marathon/conf/disable_metrics':
          ensure  => present,
          owner   => 'root',
          group   => 'root',
          mode    => '0400',
          content => '',
          notify  => Service['marathon'],
        }
      }
    }
  } else {
    file { ['/etc/marathon/conf/reporter_graphite', '/etc/marathon/conf/disable_metrics']:
      ensure => absent,
      notify => Service['marathon'],
    }
  }

  if versioncmp($version, '1.4') == 1 { # starting at version 1.5.x breaking change to user https://jira.mesosphere.com/browse/MARATHON-7970
    file_line {'marathon_config_user_root':
      path    => '/etc/default/marathon',
      line    => 'MARATHON_MESOS_USER="root"',
      require => Package['marathon'],
    }

    $zookeepers = join([ 'zk://', join(hiera('profile::mesos::common::zookeepers'), '.delivery.puppetlabs.net:2181,'), '.delivery.puppetlabs.net:2181/mesos'])
    file_line {'marathon_config_master':
      path    => '/etc/default/marathon',
      line    => "MARATHON_MASTER=\"${zookeepers}\"",
      require => Package['marathon'],
    }

    # zk defaults to localhost:2181, but in production zookeeper is not collocated
    $zookeepers_marathon = join([ 'zk://', join(hiera('profile::mesos::common::zookeepers'), '.delivery.puppetlabs.net:2181,'), '.delivery.puppetlabs.net:2181/marathon'])
    file_line {'marathon_config_zk':
      path    => '/etc/default/marathon',
      line    => "MARATHON_ZK=\"${zookeepers_marathon}\"",
      require => Package['marathon'],
    }

    file_line {'marathon_config_maintenance_mode':
      path    => '/etc/default/marathon',
      line    => "MARATHON_ENABLE_FEATURES=\"maintenance_mode\"",
      require => Package['marathon'],
    }
  }

  package { 'marathon':
    ensure  => $version,
    require => Class['profile::mesos::master'],
  }

  group { 'marathon':
    ensure  => present,
    require => Package['marathon'],
  }

  user { 'marathon':
    ensure  => present,
    gid     => 'marathon',
    require => Package['marathon'],
  }

  service { 'marathon':
    ensure    => running,
    enable    => true,
    require   => Package['marathon'],
    subscribe => Package['marathon'],
  }
}
