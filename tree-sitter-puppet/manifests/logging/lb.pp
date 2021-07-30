class profile::logging::lb {
  profile_metadata::service { $title:
    human_name        => 'Logging load balancer',
    team              => dio,
    end_users         => [
      'infrastructure-user@puppet.com',
      'discuss-sre@puppet.com',
    ],
    escalation_period => '24x7',
    downtime_impact   => "New logs are lost; users can't search Elasticsearch.",
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/Logstash+Infrastructure',
      'https://confluence.puppetlabs.com/display/SRE/Elasticsearch',
    ],
    notes             => @("NOTES"),
      Load balancer in front of both Logstash and Elasticsearch.
      |-NOTES
  }

  include keepalived
  include profile::nginx
  include profile::ssl::wildcard
  include profile::haproxy

  $keepalived_pass = hiera('profile::logging::lb::keepalived_pass')
  $keepalive_vip   = hiera('profile::logging::lb::keepalive_vip')

  haproxy::listen { "logstash-rsyslog_${facts['classification']['stage']}":
    ipaddress => '*',
    ports     => '514',
    mode      => 'tcp',
    options   => {
      'option'  => [
        'tcplog',
      ],
      'balance' => 'roundrobin',
    },
  }

  haproxy::listen { "logstash-elasticsearch-9200_${facts['classification']['stage']}":
    ipaddress => '*',
    ports     => ['9200'],
    mode      => 'http',
    options   => {
      'option'  => [
        'httplog',
        'forwardfor',
      ],
      'balance' => 'roundrobin',
    },
  }

  haproxy::listen { "logstash-elasticsearch-9300_${facts['classification']['stage']}":
    ipaddress => '*',
    ports     => ['9300'],
    mode      => 'tcp',
    options   => {
      'option'  => [
        'tcplog',
      ],
      'balance' => 'roundrobin',
    },
  }

  haproxy::listen { "logstash-kibana_${facts['classification']['stage']}":
    ipaddress => '*',
    ports     => ['80'],
    mode      => 'http',
    options   => {
      'option'  => [
        'httplog',
        'forwardfor',
      ],
      'balance' => 'source',
    },
  }

  haproxy::listen { "logstash-kibana4_${facts['classification']['stage']}":
    ipaddress => '*',
    ports     => ['8081'],
    mode      => 'http',
    options   => {
      'option'  => [
        'httplog',
        'forwardfor',
      ],
      'balance' => 'source',
    },
  }


  haproxy::listen { "logstash-forwarder-12002_${facts['classification']['stage']}":
    ipaddress => '*',
    ports     => ['12002'],
    mode      => 'tcp',
    options   => {
      'option'  => [
        'tcplog',
      ],
      'balance' => 'leastconn',
    },
  }

  haproxy::listen { "logspout_5000_${facts['classification']['stage']}":
    ipaddress => '*',
    ports     => ['5000'],
    mode      => 'tcp',
    options   => {
      'option'  => [
        'tcplog',
      ],
      'balance' => 'leastconn',
    },
  }

  haproxy::listen { "qaelk_27182_${facts['classification']['stage']}":
    ipaddress => '*',
    ports     => ['27182'],
    mode      => 'tcp',
    options   => {
      'option'  => [
        'tcplog',
      ],
      'balance' => 'leastconn',
    },
  }
  # Enable stats page
  haproxy::listen { 'stats-page':
    collect_exported => false,
    ipaddress        => '*',
    ports            => '9000',
    options          => {
      'mode'   => 'http',
      'option' => [
        'httplog',
      ],
      'stats'  =>[
        'uri /',
        'realm HAProxy\ Statistics',
        'admin if TRUE',
      ],
    },
  }

  nginx::resource::upstream { 'rev_proxy':
    cfg_prepend => $keepalive,
    members     => {
      'localhost:9200' => {
        server => 'localhost',
        port   => 9200,
      },
    },
  }
  nginx::resource::server { "${facts['networking']['fqdn']}-rev-proxy":
    listen_port => 443,
    server_name => [ $facts['networking']['fqdn'] ],
    proxy       => 'http://rev_proxy',
    ssl         => true,
    ssl_cert    => $::profile::ssl::wildcard::certchainfile,
    ssl_key     => $::profile::ssl::wildcard::keyfile,
  }

  # Keepalived config
    $keepalive_master = "logstash-lb03-${facts['classification']['stage']}.ops.puppetlabs.net"
    $keepalive_vrid = 55

  if $facts['networking']['fqdn'] == $keepalive_master {
    keepalived::vrrp::instance { 'VI_50':
      interface         => 'eth0',
      state             => 'MASTER',
      virtual_router_id => $keepalive_vrid,
      priority          => 101,
      auth_type         => 'PASS',
      auth_pass         => $keepalived_pass,
      virtual_ipaddress => $keepalive_vip,
      track_script      => 'check_haproxy',
    }
  } else {
      keepalived::vrrp::instance { 'VI_50':
        interface         => 'eth0',
        state             => 'BACKUP',
        virtual_router_id => $keepalive_vrid,
        priority          => 100,
        auth_type         => 'PASS',
        auth_pass         => $keepalived_pass,
        virtual_ipaddress => $keepalive_vip,
        track_script      => 'check_haproxy',
      }
  }

  keepalived::vrrp::script { 'check_haproxy':
    script  => 'killall -0 haproxy',
    weight  => '2',
    require => Package['keepalived'],
  }
}
