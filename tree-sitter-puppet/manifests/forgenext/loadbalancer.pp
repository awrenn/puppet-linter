class profile::forgenext::loadbalancer (
  Variant[String[1], Boolean] $keepalived_eip     = false,
  Boolean                     $export_dns_records = true,

  # Once an IP trips the rate-limit sensor, how long until
  # their exile to overflow backend expires.
  String[1] $ip_rate_limit_expire = '5m',

  # Max connection rate per IP to forgeapi frontend before
  # redirecting their requests to overflow backend.
  # Default: 10/sec sustained over a 30 second interval
  # Note: requests are distributed across 3 load balancers, and stick tables
  # and resulting request rates are not shared across load balancers.
  Hash $ip_rate_limit_api = { 'count' => 200, 'interval' => '30s' },

  # Max connection rate per IP to forgeweb frontend before
  # redirecting their requests to overflow backend.
  # Default: 3/sec sustained over a 30 second interval
  Hash $ip_rate_limit_web = { 'count' => 90, 'interval' => '30s' },
){
  $is_buster = ($facts['os']['name'] == 'Debian' and $facts['os']['release']['major'] == '10')

  # Get haproxy 2.0 from buster-backports repo
  if $is_buster {
    apt::source { 'forgenext_haproxy':
      location => 'http://haproxy.debian.net/',
      release  => "${facts['os']['distro']['codename']}-backports-2.0",
      repos    => 'main',
      key      => {
        id     => 'AEF2348766F371C689A7360095A42FE8353525F9',
        server => 'hkps.pool.sks-keyservers.net',
      },
    }

    # needed to get haproxy 2.0
    apt::pin { 'haproxy-backports-buster':
      packages => 'haproxy',
      release  => "${facts['os']['distro']['codename']}-backports-2.0",
      priority => '1000',
      require  => Apt::Source['forgenext_haproxy'],
    }

    class { 'profile::haproxy':
      package_ensure => 'latest',
      require        => Apt::Pin['haproxy-backports-buster'],
    }
  } else {
    include profile::haproxy
  }

  meta_motd::register { 'profile::forgenext::loadbalancer': }

  # the forge web front end is configured with an api_domain setting
  # which tells the user's browser where to reach the API directly.
  # For AIO instances, api_domain is the node's api vhost.
  # For normal instances, if an elastic IP is set, the api_domain should
  # point to the EIP. If no EIP is set, it should point to one or more load
  # balancers.

  if $export_dns_records {
    $api_domain_ip = $keepalived_eip ? {
      String   => $keepalived_eip, # if it has an EIP, point DNS to that
      false    => $facts['networking']['ip'],    # Otherwise, point to the node ip address.
    }

    # only one load balancer should export these DNS records, to avoid duplicate
    # exported resources
    $peers_query = "inventory {
      facts.classification.function = 'lb' and
      facts.classification.group = '${facts['classification']['group']}' and
      facts.classification.stage = '${facts['classification']['stage']}'
    }"
    $peers = puppetdb_query($peers_query).map |$value| { $value['certname'] }
    if $trusted['certname'] == $peers.sort[0] {
      @@dns_record { "${facts['classification']['group']}-api-${facts['classification']['stage']}.ops.puppetlabs.net":
        ensure  => present,
        domain  => 'ops.puppetlabs.net',
        content => $api_domain_ip,
        type    => 'A',
        ttl     => 900,
      }
      @@dns_record { "${facts['classification']['group']}-web-${facts['classification']['stage']}.ops.puppetlabs.net":
        ensure  => present,
        domain  => 'ops.puppetlabs.net',
        content => $api_domain_ip,
        type    => 'A',
        ttl     => 900,
      }
      @@dns_record { "${facts['classification']['group']}-web-react-${facts['classification']['stage']}.ops.puppetlabs.net":
        ensure  => present,
        domain  => 'ops.puppetlabs.net',
        content => $api_domain_ip,
        type    => 'A',
        ttl     => 900,
      }
    }
  }

  # if keepalive_eip is a string, assume it's a valid IP and we want
  # keepalived to be installed and take it over as our elastic IP
  if $keepalived_eip {
    include profile::websites::loadbalancer::keepalived_eip
  } else {
    package { 'keepalived':
      ensure => absent,
    }

    service {'keepalived':
      ensure    => 'stopped',
    }

    file { '/etc/keepalived/keepalived.conf':
      ensure => absent,
    }

    file { '/etc/keepalived/master.sh':
      ensure => absent,
    }
  }

  if $is_buster {
    # manually manage haproxy-check package for buster for now
    file { '/root/haproxy-check_0.0.6_amd64.deb':
      ensure => present,
      owner  => root,
      group  => root,
      mode   => '0644',
      source => 'puppet:///modules/profile/forgenext/lb/haproxy-check_0.0.6_amd64.deb',
    }

    package { 'haproxy-check':
      ensure   => latest,
      provider => dpkg,
      source   => '/root/haproxy-check_0.0.6_amd64.deb',
    }
  }

  ssl::cert::haproxy { 'wildcard.ops.puppetlabs.net': }
  ssl::cert::haproxy { 'forge.puppet.com': }
  ssl::cert::haproxy { 'forgeapi.puppet.com': }

  Haproxy::Backend {
    collect_exported => false,
  }

  Haproxy::Frontend {
    collect_exported => false,
  }

  ## The request rate and rate limiting backends are used to implement soft- and hard-rate limiting.
  # track initial request rate
  haproxy::backend { 'st_req_rate_per_30s':
    options => {
      'stick-table' => 'type ip size 200k expire 1m store conn_rate(30s)',
    },
  }

  # track whether a client is currently being soft-rate limited so they can be directed to the overflow backend
  haproxy::backend { 'st_soft_rate_limited':
    options => {
      'stick-table' => 'type ip size 200k expire 5m store gpc0',
    },
  }

  # track request rate for clients who are being soft-rate limited and directed to the overflow backend
  haproxy::backend { 'st_overflow_req_rate_per_30s':
    options => {
      'stick-table' => 'type ip size 200k expire 1m store conn_rate(30s)',
    },
  }

  # track whether a client is currently being hard-rate limited so they can receive a 429 response
  haproxy::backend { 'st_hard_rate_limited':
    options => {
      'stick-table' => 'type ip size 200k expire 10m store gpc0',
    },
  }

  file { '/etc/haproxy/errors/429.json.http':
    ensure => present,
    owner  => root,
    group  => root,
    mode   => '0644',
    source => 'puppet:///modules/profile/forgenext/429.json.http',
    notify => [
      Service['haproxy'],
    ],
  }

  haproxy::frontend { 'websites':
    bind    => {
      '0.0.0.0:80'  => [],
      # below we set forgeapi.puppet.com.crt as the default cert for clients without SNI
      '0.0.0.0:443' => ['ssl', 'crt', '/etc/haproxy/certs.d/forgeapi.puppet.com.crt', 'crt', '/etc/haproxy/certs.d', 'no-sslv3'],
    },
    options => {
      'option'          => 'forwardfor',
      'acl'             => [
        # this request will be routed to the overflow backend
        'soft_rate_limit_exceeded src_get_gpc0(st_soft_rate_limited) gt 0',
        # this request will receive a 429 response
        'hard_rate_limit_exceeded src_get_gpc0(st_hard_rate_limited) gt 0',
        # the acl settings below are needed to route https traffic to different
        # backends based on SNI rather than using a dedicated IP for each vhost
        'FORGE    hdr(Host) -i forge.puppetlabs.com',
        'FORGEAPI hdr(Host) -i forgeapi.puppetlabs.com',
        "FORGE    hdr(Host) -i forgenext-web-${facts['classification']['stage']}.${facts['networking']['domain']}",
        "FORGE    hdr(Host) -i forgenext-web-react-${facts['classification']['stage']}.${facts['networking']['domain']}",
        "FORGEAPI hdr(Host) -i forgenext-api-${facts['classification']['stage']}.${facts['networking']['domain']}",
        'FORGE    hdr(Host) -i forge.puppet.com',
        "FORGE    hdr(Host) -i forge-${facts['classification']['stage']}.puppet.com",
        'FORGEAPI hdr(Host) -i forgeapi.puppet.com',
        "FORGEAPI hdr(Host) -i forgeapi-${facts['classification']['stage']}.puppet.com",
        'FORGEAPI hdr(Host) -i forgeapi-old.puppet.com',
        'FORGEAPI hdr(Host) -i forgeapi-new.puppet.com',
      ],
      'redirect'        => [
        'scheme https code 301 if !{ ssl_fc } !{ path_beg /api/ } !{ path_beg /system/ }',
        'prefix https://forge.puppet.com code 302 if { ssl_fc_sni -i forge.puppetlabs.com } !{ path_beg /api/ }',
      ],
      'tcp-request'     => [
        # enable connection tracking in the soft limit table for this IP if not currently rate limited
        'connection track-sc0 src table st_soft_rate_limited if ! soft_rate_limit_exceeded',
        # enable connection tracking in the hard limit table for this IP if not currently rate limited
        'connection track-sc1 src table st_hard_rate_limited if ! hard_rate_limit_exceeded',
      ],
      'errorfile'       => [
        '429 /etc/haproxy/errors/429.json.http',
      ],
      'http-request'    => [
        'deny deny_status 429 if hard_rate_limit_exceeded',
        'set-header X-Forwarded-Port %[dst_port]',
        'add-header X-Forwarded-Proto https if { ssl_fc }',
      ],
      'http-response'   => [
        'add-header X-App-Server %b/%s',
        'add-header X-Lb-Server %H',
        'set-header X-UUID %ID',
      ],
      'use_backend'     => [
        # send them to the overflow backend if rate limit exceeded
        # overflow backend has approx 1/4 the concurrent request flow as normal
        'overflow if soft_rate_limit_exceeded',
        # the setting below will need to be expanded if more sites use this LB
        'forge if FORGE',
        'forgeapi if FORGEAPI',
      ],
      'default_backend' => 'forge',
    },
    require => File['/etc/haproxy/errors/429.json.http'],
  }

  ## puppet forge web site
  haproxy::backend { 'forge':
    options => {
      'acl'            => [
        "soft_conn_rate_abuse sc2_conn_rate gt ${ip_rate_limit_web['count']}",
        'soft_mark_rate_limit_exceeded sc2_inc_gpc0(st_soft_rate_limited) gt 0',
      ],
      'tcp-request'    => [
        'content track-sc2 src table st_req_rate_per_30s',

        # this accepts the last request that pushes them over the rate limit but marks
        # the IP in the frontend so the next request will be redirected to overflow backend
        'content accept if soft_conn_rate_abuse soft_mark_rate_limit_exceeded',
      ],
      'option'         => [
        'httplog',
        'httpchk GET /ping HTTP/1.1\r\nHost:forge.puppetlabs.com',
      ],
      'balance'        => 'roundrobin',
      'mode'           => 'http',
      'timeout server' => '90s',
    },
  }

  ## puppet forge API service
  haproxy::backend { 'forgeapi':
    options => {
      'acl'            => [
        "soft_conn_rate_abuse sc2_conn_rate(st_req_rate_per_30s) gt ${ip_rate_limit_api['count']}",
        'soft_mark_rate_limit_exceeded sc2_inc_gpc0(st_soft_rate_limited) gt 0',
      ],
      'tcp-request'    => [
        'content track-sc2 src table st_req_rate_per_30s',

        # this accepts the last request that pushes them over the rate limit but marks
        # the IP in the frontend so the next request will be redirected to overflow backend
        'content accept if soft_conn_rate_abuse soft_mark_rate_limit_exceeded',
      ],
      'option'         => [
        'httplog',
        'httpchk GET /ping HTTP/1.1\r\nHost:forgeapi.puppetlabs.com',
      ],
      'balance'        => 'roundrobin',
      'mode'           => 'http',
      'timeout server' => '90s',
    },
  }

  ## puppet forge backend for overflow requests
  ## (overflow reqs are requests that exceed defined per-IP rate limit)
  ## note: this backend handles both API and website requests
  haproxy::backend { 'overflow':
    options => {
      'acl'            => [
        "hard_conn_rate_abuse sc2_conn_rate(st_overflow_req_rate_per_30s) gt ${ip_rate_limit_api['count'] * 3}",
        'hard_mark_rate_limit_exceeded sc2_inc_gpc0(st_hard_rate_limited) gt 0',
      ],
      'tcp-request'    => [
        # Use st_overflow_req_rate_per_30s/sc2 for overflow backend
        'content track-sc2 src table st_overflow_req_rate_per_30s',
        'content accept if hard_conn_rate_abuse hard_mark_rate_limit_exceeded',
      ],
      'option'         => [
        'httplog',
        'httpchk GET /ping HTTP/1.1\r\nHost:forge.puppetlabs.com',
      ],
      'balance'        => 'roundrobin',
      'mode'           => 'http',
      'timeout server' => '90s',
      'http-response'  => [
        'add-header X-Rate-Limit-Exceeded 1',
      ],
    },
  }

  # find load balancer members using a puppetdb query, or set to localhost if
  # this is an AIO instance
  if $facts['classification']['function'] == 'aio' {
    $app_servers = puppetdb_query("inventory { certname = '${trusted['certname']}' }")
  } else {
    $app_servers = puppetdb_query("inventory {
      facts.classification.function = 'app' and
      facts.classification.group = '${facts['classification']['group']}' and
      facts.classification.stage = '${facts['classification']['stage']}'
    }")

    if $app_servers.count < 3 { fail('detected fewer than 3 app server backends') }
  }

  $app_servers.each |$app_server| {
    $maxconn_web      = $app_server['facts']['processorcount']
    $maxconn_api      = $maxconn_web + 2
    $maxconn_overflow = 1

    haproxy::balancermember { "${app_server['facts']['networking']['fqdn']}_forge_app":
      server_names      => "forge-${app_server['facts']['networking']['fqdn']}",
      options           => ["maxconn ${maxconn_web}", 'check' ],
      listening_service => 'forge',
      ports             => '8080',
      ipaddresses       => $app_server['facts']['primary_ip'],
    }

    haproxy::balancermember { "${app_server['facts']['networking']['fqdn']}_forgeapi_app":
      server_names      => "forgeapi-${app_server['facts']['networking']['fqdn']}",
      options           => ["maxconn ${maxconn_api}", 'check' ],
      listening_service => 'forgeapi',
      ports             => '8080',
      ipaddresses       => $app_server['facts']['primary_ip'],
    }

    haproxy::balancermember { "${app_server['facts']['networking']['fqdn']}_overflow_app":
      server_names      => "overflow-${app_server['facts']['networking']['fqdn']}",
      options           => ["maxconn ${maxconn_overflow}", 'check' ],
      listening_service => 'overflow',
      ports             => '8080',
      ipaddresses       => $app_server['facts']['primary_ip'],
    }
  }

  if $::profile::server::params::fw {
    include profile::fw::http
    include profile::fw::https
  }

  if $::profile::server::logging {
    include profile::aws::cloudwatch

    cloudwatch::log {'/var/log/haproxy.log':
      # 06/Feb/2009:12:14:14.655
      datetime_format => '%d/%b/%Y:%H:%M:%S.%f',
    }

    $hour = [3, 9, 15, 21]
    $minute = '0'

    cron { 'logrotate_haproxy':
      command => '/usr/sbin/logrotate -f /etc/logrotate.d/haproxy',
      hour    => $hour,
      minute  => $minute,
    }
  }
}
