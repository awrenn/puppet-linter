class profile::artifactory::lb {
  profile_metadata::service { $title:
    human_name => 'Artifactory lb',
    owner_uid  => 'eric.griswold',
    team       => re,
    end_users  => ['org-products@puppet.com'],
    doc_urls   => [
      'https://confluence.puppetlabs.com/display/RE/Artifactory+Basics',
    ],
  }
  include profile::haproxy

  ssl::cert::haproxy { 'wildcard.delivery.puppetlabs.net': }

  haproxy::frontend {
    default:
      collect_exported => false,
      mode             => 'http',
    ;
    ['default-80']:
      bind    => {
        '0.0.0.0:80' => [],
      },
      options => {
        redirect => 'scheme https if !{ ssl_fc }',
      },
    ;
    ['artifactory-443']:
      bind    => {
        ':443' => ['ssl', 'crt', '/etc/haproxy/certs.d', 'no-sslv3'],
      },
      options => {
        'reqirep'         => '^([^\ :]*)\ /v2(.*$) \1\ /artifactory/api/docker/docker/v2\2',
        'http-request'    => 'add-header X-Forwarded-Proto https',
        'option'          => [
          'httplog',
          'forwardfor',
          'http-server-close',
        ],
        'default_backend' => 'artifactory-8081',
      },
    ;
    ['docker']:
      bind    => {
        '*:5000' => ['ssl', 'crt', '/etc/haproxy/certs.d', 'no-sslv3'],
      },
      options => {
        'reqadd'          => 'X-Forwarded-Proto:\ https if { ssl_fc }',
        'reqirep'         => '^([^\ :]*)\ /v2(.*$) \1\ /artifactory/api/docker/docker/v2\2',
        'option'          => [
          'forwardfor',
          'forwardfor header X-Real-IP',
        ],
        'default_backend' => 'artifactory-8081',
      },
    ;
    ['dockerprod']:
      bind    => {
        '*:5001' => ['ssl', 'crt', '/etc/haproxy/certs.d', 'no-sslv3'],
      },
      options => {
        'reqadd'          => 'X-Forwarded-Proto:\ https if { ssl_fc }',
        'reqirep'         => '^([^\ :]*)\ /v2(.*$) \1\ /artifactory/api/docker/docker__local/v2\2',
        'option'          => [
          'forwardfor',
          'forwardfor header X-Real-IP',
        ],
        'default_backend' => 'artifactory-8081',
      },
    ;
  }

    haproxy::backend { 'artifactory-8081':
      options     => {
        'option'  => [
          'httplog',
        ],
        'mode'    => 'http',
        'balance' => 'roundrobin',
      },
    }

    $balancer_members = unique(puppetdb_query("inventory {
      facts.classification.group = '${facts['classification']['group']}' and
      facts.classification.stage = '${facts['classification']['stage']}' and
      facts.whereami             = '${facts['whereami']}' and
      resources {
        type = 'Class' and
        title = 'Profile::Artifactory::App'
      }
    }").map |$value| { $value['facts']['networking']['ip'] })

    $balancer_members.each |$client_ipaddress| {
      haproxy::balancermember { "artifactoryapp_balancermember_${client_ipaddress}_${facts['classification']['group']}_${facts['classification']['stage']}":
        listening_service => 'artifactory-8081',
        server_names      => "artifactoryapp_${client_ipaddress}",
        ipaddresses       => $client_ipaddress,
        ports             => '8081',
        options           => ['check'],
      }
    }

    # Enable stats page
    haproxy::listen { 'artfactory-admin':
      ipaddress => '*',
      ports     => '9000',
      mode      => 'http',
      options   => {
        'option' => [
          'httplog',
        ],
        'stats'  => [
          'uri /',
          'realm HAProxy\ Statistics',
          'admin if TRUE',
        ],
      },
    }
}
