# Class: profile::pe::lb
#
# Manage HAProxy load balancer for PE compiler nodes
#
class profile::pe::lb (
  Stdlib::Httpurl $consul_server,
  Stdlib::Fqdn $consul_domain = 'consul.puppet.net',
  String[1] $consul_dc = lookup('profile::consul::datacenter'),
) {
  profile_metadata::service { $title:
    human_name        => 'Puppet Enterprise load balancer',
    owner_uid         => 'gene.liverman',
    team              => dio,
    end_users         => ['notify-infracore@puppet.com'],
    escalation_period => 'global-workhours',
    downtime_impact   => "Can't make changes to infrastructure",
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/SRE+Internal+Puppet+Infrastructure+Service+Docs',
    ],
    other_fqdns       => ['puppet.ops.puppetlabs.net'],
    notes             => @("NOTES"),
      Puppet agents connect to this rather than directly to the compilers.
      |-NOTES
  }

  include profile::os::linux::redhat::scl_repos

  selinux::boolean { 'haproxy_connect_any': }

  if $facts['whereami'] == 'aws_internal_net_vpc' {

    include keepalived

    class{ 'profile::aws::cli':
      require => Package['pip'],
    }

    $keepalived_pass      = lookup('profile::pe::lb::keepalived_pass')
    $vip                  = lookup('profile::pe::lb::vip')
    $vip_cidr_format      = "${$vip}/24"
    $peer_query           = puppetdb_query("inventory {
      facts.classification.group    = '${facts['classification']['group']}' and
      facts.classification.function = '${facts['classification']['function']}' and
      facts.classification.stage    = '${facts['classification']['stage']}'
    }")

    $peer_ips   = sort(unique($peer_query.map |$value| { $value['facts']['networking']['ip'] }))
    $peer_fqdns = sort(unique($peer_query.map |$value| { $value['facts']['networking']['fqdn'] }))

    if is_array($peer_fqdns) {
      $peers = $peer_fqdns
    } else {
      $peers = []
    }

    if count($peers) < 2 {
      notify{'profile::pe::lb found < 2 keepalive nodes; this is expected while bootstrapping a pair but indicates a problem otherwise': }
    }

    # determine which LB should be the keepalived master
    # it doesn't matter which node it is as long as only one is selected
    if count($peers) == 0 {
      # if no nodes were found in puppetdb, this must be bootstrapping a pair
      notify { "bootstrapping keepalive pair with ${facts['networking']['fqdn']} as keepalive master": }
      $keepalive_master = $facts['networking']['fqdn']
    } else {
      $keepalive_master = $peers[0]
    }
    if (count($peers) == 1) and $peers[0] == $facts['networking']['fqdn'] {
      notify { 'Warning: this node is a keepalive master but no backup nodes were found in puppetdb': }
      exec { 'aquire LB VIP and restart keepalived':
        path    => '/etc/keepalived',
        command => 'master.sh',
        notify  => Service['keepalived'],
      }
    }

    # only one balancer member should be primary
    # all other members should be backup and only used if the first is down
    $keepalived_role = $facts['networking']['fqdn'] ? {
      $peers[0] => 'MASTER',
      default    => 'BACKUP',
    }

    $unicast_peer_ips = delete($peer_ips, $facts['networking']['ip'])
    $keepalived_priority = $keepalived_role ? {
      'MASTER' => 101,
      default  => 100,
    }

    keepalived::vrrp::instance { 'VI_50':
      interface            => $facts['networking']['primary'],
      state                => $keepalived_role,
      virtual_router_id    => 50,
      priority             => $keepalived_priority,
      auth_type            => 'PASS',
      auth_pass            => $keepalived_pass,
      virtual_ipaddress    => $vip_cidr_format,
      unicast_source_ip    => $facts['networking']['ip'],
      unicast_peers        => $unicast_peer_ips,
      track_script         => 'check_haproxy',
      notify_script_master => '/etc/keepalived/master.sh',
    }

    keepalived::vrrp::script { 'check_haproxy':
      script  => 'killall -0 haproxy',
      weight  => '2',
      require => Package['keepalived'],
    }

    # this script is run by keepalive when the node is promoted to master
    # it takes over the elastic IP address
    file { '/etc/keepalived/master.sh':
      owner   => 'root',
      group   => 'root',
      mode    => '0750',
      content => epp('profile/pe/lb/master_vip.sh.epp', { 'vip' => $vip }),
      before  => Service['keepalived'],
    }
  }

  package { 'stock haproxy':
    ensure => 'absent',
    name   => 'haproxy',
    before => Class['haproxy'],
  }

  class { 'haproxy':
    package_name        => 'rh-haproxy18',
    config_dir          => '/etc/opt/rh/rh-haproxy18/haproxy',
    config_file         => '/etc/opt/rh/rh-haproxy18/haproxy/haproxy.cfg',
    config_validate_cmd => '/bin/scl enable rh-haproxy18 "haproxy -f % -c"',
    service_name        => 'rh-haproxy18-haproxy',
    global_options      => {
      'log'                        => '127.0.0.1 local2',
      'chroot'                     => '/var/opt/rh/rh-haproxy18/lib/haproxy',
      'pidfile'                    => '/var/run/rh-haproxy18-haproxy.pid',
      'maxconn'                    => '4000',
      'user'                       => 'haproxy',
      'group'                      => 'haproxy',
      'daemon'                     => '',
      'stats'                      => 'socket /var/opt/rh/rh-haproxy18/lib/haproxy/stats',
      # set default parameters to the intermediate configuration per https://mozilla.github.io/server-side-tls/ssl-config-generator/
      'tune.ssl.default-dh-param'  => '2048',
      'ssl-default-bind-ciphers'   => 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS',
      'ssl-default-bind-options'   => 'no-sslv3 no-tls-tickets',
      'ssl-default-server-ciphers' => 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS',
      'ssl-default-server-options' => 'no-sslv3 no-tls-tickets',
    },
    defaults_options    => {
      'mode'    => 'tcp',
      'balance' => 'leastconn',
      'log'     => 'global',
      'maxconn' => '8000',
      'option'  => [
        'tcplog',
        'dontlognull',
        'http-server-close',
        'forwardfor except 127.0.0.0/8',
        'redispatch',
      ],
      'retries' => '3',
      'timeout' => [
        'http-request 10s',
        'queue 30m',
        'connect 10s',
        'client 20m',
        'server 20m',
        'http-keep-alive 10s',
        'check 10s',
      ],
    },
    require             => Class['profile::os::linux::redhat::scl_repos'],
  }

  package { 'rh-haproxy18-haproxy-syspaths':
    ensure  => present,
    require => Class['haproxy'],
  }

  # haproxyctl is a CLI tool for interacting with haproxy
  package { 'haproxyctl':
    ensure   => 'present',
    provider => 'gem',
  }

  include haproxy_consul::puppet_ca_files

  haproxy_consul::resolver { $consul_server: }

  $_haproxy_cert_dir = lookup('haproxy_consul::puppet_ca_files::haproxy_cert_dir')
  $_puppet_ca_file  = "${_haproxy_cert_dir}/${lookup('haproxy_consul::puppet_ca_files::puppet_ca_file_name')}"
  $_puppet_crl_file = "${_haproxy_cert_dir}/${lookup('haproxy_consul::puppet_ca_files::puppet_crl_file_name')}"

  haproxy_consul::server_template {
    default:
      consul_domain => "${consul_dc}.${consul_domain}",
      amount        => '1',
      require       => Class['Haproxy_consul::Puppet_ca_files'],
    ;
    'pe-console-http':
      ports                  => '80',
      listen_options         => {
        'balance' => 'roundrobin',
        'option'  => [
          'httpchk',
        ],
      },
      balancermember_options => [
        'resolvers consul',
        'resolve-prefer ipv4',
        'check',
      ],
    ;
    'pe-console-https':
      ports                  => '443',
      listen_options         => {
        'balance' => 'roundrobin',
        'option'  => [
          'ssl-hello-chk',
        ],
      },
      balancermember_options => [
        'resolvers consul',
        'resolve-prefer ipv4',
        'check',
      ],
    ;
    'pe-rbac-api':
      ports                  => '4433',
      listen_options         => {
        'option httpchk' => 'get /status/v1/simple',
      },
      balancermember_options => [
        'resolvers consul',
        'resolve-prefer ipv4',
        'check check-ssl',
        'port 4433',
        'verify required',
        "ca-file ${_puppet_ca_file}",
        "crl-file ${_puppet_crl_file}",
      ],
    ;
    'pe-compiler-puppetdb-api':
      ports                  => '8081',
      listen_options         => {
        'option httpchk' => 'get /status/v1/simple',
      },
      balancermember_options => [
        'resolvers consul',
        'resolve-prefer ipv4',
        'check check-ssl',
        'port 8081',
        'verify required',
        "ca-file ${_puppet_ca_file}",
        "crl-file ${_puppet_crl_file}",
      ],
      amount                 => '8',
    ;
    'pe-compiler-puppet-agent':
      ports                  => '8140',
      listen_options         => {
        'option httpchk' => 'get /status/v1/simple/master',
      },
      balancermember_options => [
        'resolvers consul',
        'resolve-prefer ipv4',
        'check check-ssl',
        'port 8140',
        'verify required',
        "ca-file ${_puppet_ca_file}",
        "crl-file ${_puppet_crl_file}",
      ],
      amount                 => '8',
    ;
    'pe-compiler-pxp-agent':
      ports                  => '8142',
      listen_options         => {
        'option httpchk' => 'get /status/v1/simple/broker-service',
        'timeout'        => 'tunnel 15m',
      },
      balancermember_options => [
        'resolvers consul',
        'resolve-prefer ipv4',
        'check check-ssl',
        'port 8140', # explicitly set to the agent port
        'verify required',
        "ca-file ${_puppet_ca_file}",
        "crl-file ${_puppet_crl_file}",
      ],
      amount                 => '8',
    ;
    'pe-orchestrator-api':
      ports                  => '8143',
      listen_options         => {
        'option httpchk' => 'get /status/v1/simple',
      },
      balancermember_options => [
        'resolvers consul',
        'resolve-prefer ipv4',
        'check check-ssl',
        'port 8143',
        'verify required',
        "ca-file ${_puppet_ca_file}",
        "crl-file ${_puppet_crl_file}",
      ],
    ;
    'pe-code-manager-api':
      ports                  => '8170',
      listen_options         => {
        'option httpchk' => 'get /status/v1/simple/code-manager-service',
      },
      balancermember_options => [
        'resolvers consul',
        'resolve-prefer ipv4',
        'check check-ssl',
        'port 8140', # explicitly set to the agent port
        'verify required',
        "ca-file ${_puppet_ca_file}",
        "crl-file ${_puppet_crl_file}",
      ],
    ;
  }

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
}
