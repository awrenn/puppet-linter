class profile::graphite::lb {
  profile_metadata::service { $title:
    human_name        => 'Graphite load balancer',
    team              => dio,
    end_users         => [
      'infrastructure-user@puppet.com',
      'discuss-sre@puppet.com',
    ],
    escalation_period => '24x7',
    downtime_impact   => "New metrics are lost; users can't access metrics.",
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/Graphite+Service+Page',
    ],
  }

  include profile::haproxy

  if $facts['classification']['stage'] == 'prod' {
    include keepalived
    $keepalived_pass = hiera('profile::graphite::lb::keepalived_pass')
    $vip             = hiera('profile::graphite::lb::vip')

    if $facts['networking']['fqdn'] =~ /^graphite-lb0(1|3)-prod\.ops\.puppetlabs\.net$/ {
      keepalived::vrrp::instance { 'VI_50':
        interface         => 'eth0',
        state             => 'MASTER',
        virtual_router_id => 50,
        priority          => 101,
        auth_type         => 'PASS',
        auth_pass         => $keepalived_pass,
        virtual_ipaddress => $vip,
        track_script      => 'check_haproxy',
      }
    } else {
      keepalived::vrrp::instance { 'VI_50':
        interface         => 'eth0',
        state             => 'BACKUP',
        virtual_router_id => 50,
        priority          => 100,
        auth_type         => 'PASS',
        auth_pass         => $keepalived_pass,
        virtual_ipaddress => $vip,
        track_script      => 'check_haproxy',
      }
    }

    keepalived::vrrp::script { 'check_haproxy':
      script  => 'killall -0 haproxy',
      weight  => '2',
      require => Package['keepalived'],
    }
  }

  haproxy::frontend {
    default:
      collect_exported => false,
      mode             => 'tcp',
    ;
    ['graphite-haproxy-2003']:
      bind    => {
        '0.0.0.0:2003' => [],
      },
      options => {
        'option'          => [
          'tcplog',
        ],
        'balance'         => 'leastconn',
        'default_backend' => 'graphite-2003',
      },
    ;
    ['graphite-haproxy-2004']:
      bind    => {
        '0.0.0.0:2004' => [],
      },
      options => {
        'option'          => [
          'tcplog',
        ],
        'balance'         => 'leastconn',
        'default_backend' => 'graphite-2004',
      },
    ;
    ['graphite-default-80']:
      bind    => {
        '0.0.0.0:80' => [],
      },
      mode    => 'http',
      options => {
        'option'          => [
          'httplog',
        ],
        'acl'             => [
          'GRAFANA hdr(host) -i grafana.ops.puppetlabs.net',
          'GRAPHITE hdr(host) -i graphite.ops.puppetlabs.net',
        ],
        'use_backend'     => [
          'graphite-80 if GRAPHITE',
          'grafana-80 if GRAFANA',
        ],
        'default_backend' => 'graphite-80',
      },
    ;
    ['old-grafana-8080']:
      bind    => {
        '0.0.0.0:8080' => [],
      },
      mode    => 'http',
      options => {
        'option'          => [
          'httplog',
        ],
        'default_backend' => 'grafana-8080',
      },
    ;
    ['old-grafana-3000']:
      bind    => {
        '0.0.0.0:3000' => [],
      },
      mode    => 'http',
      options => {
        'option'          => [
          'httplog',
        ],
        'default_backend' => 'grafana-3000',
      },
    ;
  }

  haproxy::backend {
    default:
      options     => {
        'option' => [
          'httplog',
        ],
        'cookie' => 'grafana_sess prefix indirect nocache',
        'mode'   => 'http',
      },
    ;
    ['grafana-80', 'grafana-3000', 'grafana-8080']:
    ;
    ['graphite-80']:
      options     => {
        'option' => [
          'httplog',
        ],
        'mode'   => 'http',
      },
    ;
    ['graphite-2003','graphite-2004']:
      options     => {
        'option'  => [
          'tcplog',
        ],
        'balance' => 'leastconn',
        'mode'    => 'tcp',
      },
    ;
  }

  # Enable stats page
  haproxy::listen { 'graphite-admin':
    ipaddress => '*',
    ports     => '8081',
    mode      => 'http',
    options   => {
      'stats'   => 'enable',
    },
  }

}
