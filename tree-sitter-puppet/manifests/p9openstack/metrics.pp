class profile::p9openstack::metrics (
  String[1] $platform9_host = 'puppet.platform9.net',
) {
  telegraf::input { 'platform9_instance_launch_time_logparser':
    plugin_type => 'logparser',
    options     => [{
      'files'          => ['/var/log/pf9/ostackhost.log'],
      'from_beginning' => true,
      'grok'           => {
        'measurement'          => 'platform9_logs',
        'custom_pattern_files' => [],
        'patterns'             => [
          '%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:log_level} %{SYSLOGPROG:syslog_prog} \\[req-%{UUID:userid} %{USERNAME}@puppet.com \\S*\] \\[instance: %{UUID:hostid}\\] Took %{NUMBER:time_to_launch:float} seconds to build instance.',
          '%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:log_level} %{SYSLOGPROG:syslog_prog} \\[req-%{UUID:userid} %{USERNAME}@puppet.com \\S*\] \\[instance: %{UUID:hostid}\\] Took %{NUMBER:time_to_destroy:float} seconds to destroy the instance on the hypervisor.',
        ],
      },
    }],
  }

  telegraf::input { 'platform9_glance_http_response':
    plugin_type => 'http_response',
    options     => [{
      'address' => 'http://localhost:9292',
    }],
  }

  telegraf::input { 'platform9_nova_http_response':
    plugin_type => 'http_response',
    options     => [{
      'address' => 'https://puppet.platform9.net/nova/v3/status',
    }],
  }

  file { '/opt/metrics_scripts/':
    ensure => 'directory',
    owner  => 'telegraf',
    group  => 'telegraf',
  }

  file { '/opt/metrics_scripts/traceroute_test.sh':
    content => epp('profile/metrics/traceroute_test.sh.epp',  { 'hostname' => $platform9_host }),
    mode    => '0755',
    owner   => 'telegraf',
    group   => 'telegraf',
  }

  package { 'traceroute': }

  telegraf::input { 'platform9_traceroute_hops':
    plugin_type => 'exec',
    options     =>  [{
      commands    => [
        '/opt/metrics_scripts/traceroute_test.sh',
      ],
      data_format => 'influx',
      interval    => '10m',
      timeout     => '5s',
    }],
    require     => Package['traceroute'],
  }
}
