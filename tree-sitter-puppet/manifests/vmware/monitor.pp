class profile::vmware::monitor inherits profile::monitoring::icinga2::common {

  package { ['rbvmomi', 'rest-client']:
    ensure   => present,
    provider => 'gem',
    require  => Package['ruby-dev'],
  }

# Paid Certificate nodes
  $vcenter_hosts = [
    'vcenter-ci1.ops.puppetlabs.net',
    'vcenter-prod1.ops.puppetlabs.net',
  ]
  each($vcenter_hosts) |$host| {
    icinga2::object::host { $host:
      check_command => 'hostalive',
      display_name  => $host,
      ipv4_address  => $host,
    }

    @@icinga2::object::service { "ssl-cert-valid-${host}":
      check_command      => 'check_ssl_cert',
      check_interval     =>  '1m',
      retry_interval     =>  '1m',
      max_check_attempts =>  10,
      vars               => {
        host          => $host,
        rootcert      => '/etc/ssl/certs',
        escalate      => true,
        warning_days  => '30',
        critical_days => '7',
      },
      tag                => ['singleton'],
    }
  }

# Self-signed certificate hosts
  $self_vcenter_hosts = [
    # currently we don't have any of these but the logic took us long enough
    # to come up with that I want to leave it here for now. --Gene Aug. 2018
  ]
  each($self_vcenter_hosts) |$host| {
    icinga2::object::host { $host:
      check_command => 'hostalive',
      display_name  => $host,
      ipv4_address  => $host,
    }

    @@icinga2::object::service { "ssl-cert-valid-${host}":
      check_command      => 'check_ssl_cert',
      check_interval     =>  '1m',
      retry_interval     =>  '1m',
      max_check_attempts =>  10,
      vars               => {
        host          => $host,
        rootcert      => '/etc/ssl/certs',
        escalate      => true,
        warning_days  => '30',
        critical_days => '7',
        no_auth       => true,
        self_signed   => true,
      },
      tag                => ['singleton'],
    }
  }

  @@icinga2::object::service { 'vcenter-ci1.ops.puppetlabs.net-vcenter':
    object_servicename => 'vcenter',
    host_name          => 'vcenter-ci1.ops.puppetlabs.net',
    check_command      => 'vcenter',
    vars               => {
      'instance_uuid' => '4231e051-0579-5479-e94c-ddda59c2066f', # this is pointing at centos-7-7x86_64-monitoring-canary
      'host'          => 'vcenter-ci1.ops.puppetlabs.net',
      'user'          => lookup('monitoring::vcenter::vcenter_user'),
      'password'      => lookup('monitoring::vcenter::vcenter_passwd'),
    },
    tag                => ['singleton'],
  }

  @@icinga2::object::service { 'vcenter-prod1.ops.puppetlabs.net-vcenter':
    object_servicename => 'vcenter',
    host_name          => 'vcenter-prod1.ops.puppetlabs.net',
    check_command      => 'vcenter',
    vars               => {
      'instance_uuid' => '420f20ab-6bad-86a1-264e-9da69017f6e6', # this is pointing at the centos60-i386 template
      'host'          => 'vcenter-prod1.ops.puppetlabs.net',
      'user'          => lookup('monitoring::vcenter::vcenter_user'),
      'password'      => lookup('monitoring::vcenter::vcenter_passwd'),
    },
    tag                => ['singleton'],
  }

  @@icinga2::object::service { 'veso-core-count':
    check_command  => 'graphite-metric',
    check_interval => '15m',
    vars           => {
      'url'      => 'graphite.ops.puppetlabs.net',
      'function' => 'average',
      'metric'   => 'minSeries(vmware.cluster.acceptance1.cores)',
      'warning'  => '420',
      'critical' => '400',
      'duration' => '20',
    },
    tag            => ['singleton'],
  }

  # These hosts are physical UCS blades running ESXi with statsfeeder metrics
  $graphite_esxi_hosts = [
    'opdx-a2-chassis1-1.ops.puppetlabs.net',
    'opdx-a2-chassis1-2.ops.puppetlabs.net',
    'opdx-a2-chassis1-3.ops.puppetlabs.net',
    'opdx-a2-chassis1-4.ops.puppetlabs.net',
    'opdx-a2-chassis1-5.ops.puppetlabs.net',
    'opdx-a2-chassis1-6.ops.puppetlabs.net',
    'opdx-a2-chassis1-7.ops.puppetlabs.net',
    'opdx-a2-chassis1-8.ops.puppetlabs.net',
    'opdx-a0-chassis5-1.ops.puppetlabs.net',
    'opdx-a0-chassis5-2.ops.puppetlabs.net',
    'opdx-a0-chassis5-3.ops.puppetlabs.net',
    'opdx-a0-chassis5-4.ops.puppetlabs.net',
    'opdx-a0-chassis5-5.ops.puppetlabs.net',
    'opdx-a0-chassis5-6.ops.puppetlabs.net',
    'opdx-a0-chassis5-7.ops.puppetlabs.net',
    'opdx-a0-chassis5-8.ops.puppetlabs.net',
    'opdx-a2-chassis6-1.ops.puppetlabs.net',
    'opdx-a2-chassis6-2.ops.puppetlabs.net',
    'opdx-a2-chassis6-3.ops.puppetlabs.net',
    'opdx-a2-chassis6-4.ops.puppetlabs.net',
    'opdx-a2-chassis6-5.ops.puppetlabs.net',
    'opdx-a2-chassis6-6.ops.puppetlabs.net',
    'opdx-a2-chassis6-7.ops.puppetlabs.net',
    'opdx-a2-chassis6-8.ops.puppetlabs.net',
    'opdx-e6-chassis8-1.ops.puppetlabs.net',
    'opdx-e6-chassis8-2.ops.puppetlabs.net',
    'opdx-e6-chassis8-3.ops.puppetlabs.net',
    'opdx-e6-chassis8-4.ops.puppetlabs.net',
    'opdx-e6-chassis8-5.ops.puppetlabs.net',
    'opdx-e6-chassis8-6.ops.puppetlabs.net',
    'opdx-e6-chassis8-7.ops.puppetlabs.net',
    'opdx-e6-chassis8-8.ops.puppetlabs.net',
    'pix-jj26-chassis1-1.ops.puppetlabs.net',
    'pix-jj26-chassis1-2.ops.puppetlabs.net',
    'pix-jj26-chassis1-3.ops.puppetlabs.net',
    'pix-jj26-chassis1-4.ops.puppetlabs.net',
    'pix-jj26-chassis1-5.ops.puppetlabs.net',
    'pix-jj26-chassis1-6.ops.puppetlabs.net',
    'pix-jj26-chassis1-7.ops.puppetlabs.net',
    'pix-jj26-chassis1-8.ops.puppetlabs.net',
  ]

  # Hosts without statsfeeder metrics
  $esxi_hosts = [
    'opdx-support-vmwhyperv1.ops.puppetlabs.net',
    'opdx-support-vmwhyperv2.ops.puppetlabs.net',
    'opdx-support-vmwhyperv3.ops.puppetlabs.net',
  ]

  each($esxi_hosts) |$s| {
    icinga2::object::host { $s:
      check_command => 'hostalive',
      display_name  => $s,
      ipv4_address  => $s,
    }
  }

  $graphite_metrics = ['cpu', 'mem']
  $graphite_url = 'http://graphite.ops.puppetlabs.net'

  each($graphite_esxi_hosts) |$s| {
    icinga2::object::host { $s:
      check_command => 'hostalive',
      display_name  => $s,
      ipv4_address  => $s,
      vars          => {
        escalate => true,
      },
    }
    each($graphite_metrics) |$m| {
      @@icinga2::object::service { "${s}-graphite-metrics-${m}":
        object_servicename => "graphite-metric-${m}",
        host_name          => $s,
        check_command      => 'graphite-metric',
        vars               => {
          'url'      => $graphite_url,
          'function' => 'average',
          'metric'   => "scale(vmware.ESXi.${regsubst($s, '\.', '_', 'G')}.${m}.usage.average,0.01)",
          'warning'  => '90',
          'critical' => '99',
          'duration' => '480',
        },
        tag                => ['singleton'],
      }
    }
  }
}
