# == Class: profile::forge::web
#
# Gerenal profile class for createing Forge Web Service Instances.
# Special attention should be given to the $acceptance_flag as it triggers
# specific funtionality for this profile.  It enable the use of this profile
# in a Forge Acceptance instance.  Setting this value to true in hiera allows
# simultaneous coexistance with the Forge API Application.
#
# === Authors
#
#  Puppet Ops <opsteam@puppetlabs.com>
#
# === Copyright
#
# Copyright 2014 Puppet Labs, unless otherwise noted.
#
class profile::forge::web (
  $session_secret,
  $api_url                           = undef,
  $client_id                         = undef,
  $client_secret                     = undef,
  $user                              = 'forge-web',
  $group                             = 'forge-web',
  $user_home                         = '/var/lib/forge-web',
  $source                            = 'git@github.com:puppetlabs/puppet-forge-web',
  $app_root                          = '/opt/forge-web',
  $manageuser                        = true,
  $nginx_opts                        = {},
  $newrelic_key                      = '511674b2125d79323ea0605d1ab63617867cbefe',
  $exceptional_api_key               = '84549fbf7595ec42c628288cefac73a05a1ea882',
  $rack_env                          = 'production',
  $statsd_svr                        = '127.0.0.1:8125',
  $unicorn_workers                   = '8',
  $log_level                         = undef,
  $vhost                             = $facts['networking']['hostname'],
  $acceptance_flag                   = false,
  $acceptance_type                   = 'aio',
  $acceptance_aliases                = [ "web-${facts['networking']['fqdn']}" ],
  $nginx_port                        = '80',
  $nginx_sslport                     = '443',
  $statsd_prefix                     = "${facts['classification']['group']}.${facts['classification']['stage']}.${facts['classification']['function']}${facts['classification']['number_string']}.web", # lint:ignore:140chars
  String[1] $canonical_fqdn          = "web-${facts['networking']['fqdn']}",
  Array[String[1]] $legacy_hostnames = [],
) {
  profile_metadata::service { $title:
    human_name        => 'Forge Web Server',
    team              => 'forge',
    end_users         => ['notify-infracore@puppet.com'],
    escalation_period => 'pdx-workhours',
    downtime_impact   => @(END),
      Legacy profile used only by internal PE testing infrastructure, PE integration tests might fail
      | END
  }

  include profile::server
  include profile::forge::shared

  include profile::forge::rbenv

  # Sanity checks:
  $valid_acceptance_types = ['aio','vulcanapi']
  validate_re($acceptance_type, $valid_acceptance_types)
  validate_bool($acceptance_flag)

  if ($profile::server::logging == true) {
    include profile::logging::logstashforwarder
  }

  if ($profile::server::metrics == true) {
    include profile::metrics::diamond::client
    include profile::metrics::diamond::collectors

    Diamond::Collector <| title == 'NginxCollector' |> {
      options      => {
        'req_port' => 70,
      }
    }
  }

  # Other includes
  include puppetlabs::ssl
  include git

  if $manageuser {
    group { $group:
      ensure => present,
    }

    user { $user:
      ensure     => present,
      shell      => '/bin/bash',
      gid        => $group,
      groups     => 'forge-admins',
      password   => '*',
      system     => true,
      comment    => 'Puppet Labs Blacksmith',
      home       => $user_home,
      managehome => true,
      require    => Group[$group],
      before     => File[$app_root],
    }
  }

  file { "${user_home}/.bash_aliases":
    ensure  => 'present',
    owner   => $user,
    group   => $group,
    mode    => '0700',
    content => template('profile/forge/bash_aliases.erb'),
    require => User[$user],
  }

  file { "${user_home}/.ssh":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0700',
    require => User[$user],
  }

  file {"${user_home}/.ssh/id_rsa":
    ensure  => 'present',
    source  => 'puppet:///modules/profile/forge/id_rsa_forge',
    owner   => $user,
    group   => $group,
    mode    => '0600',
    require => File["${user_home}/.ssh"],
  }

  # TODO: we should build the authorized keys file
  if $facts['classification']['stage'] == 'stage' {
    $user_authorized_keys = 'puppet:///modules/profile/forge/ssh_authorized_keys_staging'
  }
  else {
    $user_authorized_keys = 'puppet:///modules/profile/forge/ssh_authorized_keys'
  }

  file {"${user_home}/.ssh/authorized_keys":
    ensure  => 'present',
    source  => $user_authorized_keys,
    owner   => $user,
    group   => $group,
    mode    => '0600',
    require => File["${user_home}/.ssh"],
  }

  # Ensure that the $app_root exists and is writable.
  file { $app_root:
    ensure => directory,
    owner  => $user,
    group  => $group,
  }

  file { [ "${app_root}/config", "${app_root}/log", "${app_root}/assets" ]:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    require => File[$app_root],
  }

  $canonical_api_fqdn = hiera('profile::forge::api::canonical_fqdn', "api-#{facts['networking']['fqdn']}")
  file { "${app_root}/config/settings.yml":
    ensure  => file,
    owner   => $user,
    group   => $group,
    mode    => '0640',
    content => template('profile/forge/web/settings.yml.erb'),
    require => File["${app_root}/config"],
    notify  => Unicorn::App['forge-web'],
  }

  file { "${app_root}/config/newrelic.yml":
    ensure  => file,
    owner   => $user,
    group   => $group,
    mode    => '0640',
    content => template('profile/forge/web/newrelic.yml.erb'),
    require => File["${app_root}/config"],
    notify  => Unicorn::App['forge-web'],
  }

  file { "${app_root}/config/exceptional.yml":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0640',
    content => template('profile/forge/web/exceptional.yml.erb'),
    require => File["${app_root}/config"],
    notify  => Unicorn::App['forge-web'],
  }

  $robotstxt = $facts['classification']['stage'] ? {
    'prod'  => 'puppet:///modules/profile/forge/web/robots-prod.txt',
    default => 'puppet:///modules/profile/forge/robots-disallow-all.txt',
  }

  file { "${app_root}/assets/robots.txt":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0644',
    source  => $robotstxt,
    require => File["${app_root}/assets"],
  }

  unless $acceptance_flag {
    include unicorn
  }
  include nokogiri

  $unicorn_socket  = "${user_home}/unicorn.sock"
  $unicorn_pidfile = "${user_home}/unicorn.pid"

  unicorn::app { 'forge-web':
    approot         => "${app_root}/current",
    workers         => $unicorn_workers,
    pidfile         => $unicorn_pidfile,
    socket          => $unicorn_socket,
    user            => $user,
    group           => $group,
    config_file     => "${app_root}/config/forge-unicorn.rb",
    config_template => 'profile/forge/web/unicorn_config.rb.erb',
    preload_app     => true,
    rack_env        => $rack_env,
    source          => '/usr/local/rbenv/shims/ruby ./bin/unicorn',
    init_time       => 120,
    require         => [
      File["${app_root}/config"],
      Class['ruby::dev'],
      Class['profile::forge::rbenv'],
    ],
  }

  # Acceptance Settings:
  if $acceptance_flag {
    # Check the accpetance instance type:
    # - AIO = All-In-One
    # - VulcanAPI
    if $acceptance_type == 'aio'{
      $servername = "${vhost}-web"
    } else {
      $servername = $vhost
    }
    $acceptance_nginx_params = {
      servername     => $servername,
      serveraliases  => $acceptance_aliases,
      isdefaultvhost => false,
      ssl            => false,
      port           => '8088',
    }
  } else {
    $servername              = $vhost
    $acceptance_nginx_params = {
      servername     => $servername,
      ssl            => true,
      isdefaultvhost => true,
    }
  }

  # Nginx Configuration
  include profile::nginx

  $socket = "unix:${unicorn_socket}"
  nginx::resource::upstream { 'unicorn-web':
    members     => {
      "${socket}" => {
        server       => $socket,
        fail_timeout => '0',
      },
    },
    cfg_prepend => {
      'keepalive' => '10',
    },
  }

  # Always include forge.puppetlabs.com as a legacy hostname. Often internal
  # systems access non-production forge using that hostname.
  $all_legacy_hostnames = unique($legacy_hostnames + [ 'forge' ])

  ssl::cert { 'forge.puppet.com': }

  nginx::resource::server {
    default:
      ensure               => present,
      use_default_location => false,
      listen_port          => scanf($nginx_port, '%i')[0],
      ssl                  => true,
      ssl_port             => scanf($nginx_sslport, '%i')[0],
      www_root             => '/opt/forge-web/current/public',
      client_max_body_size => '10m',
      access_log           => '/var/log/nginx/forgestaging.puppetlabs.com.access.log',
      format_log           => 'logstash_json',
      proxy_set_header     => ['X-Forwarded-For $proxy_add_x_forwarded_for', 'X-Real-IP $remote_addr', 'X-Forwarded-Proto $scheme', 'Host $http_host'], # lint:ignore:140chars
    ;
    'forge-web':
      server_name => [ $canonical_fqdn, 'forge.puppet.com' ].unique(),
      ssl_cert    => '/etc/ssl/certs/forge.puppet.com_combined.crt',
      ssl_key     => '/etc/ssl/private/forge.puppet.com.key',
    ;
    'forge-web-legacy':
      server_name => $all_legacy_hostnames.map |$h| { "${h}.puppetlabs.com" },
      ssl_cert    => $profile::ssl::wildcard::certchainfile,
      ssl_key     => $profile::ssl::wildcard::keyfile,
    ;
  }

  nginx::resource::location { 'forge-web redirect to SSL':
    server              => 'forge-web',
    location            => '/',
    location_custom_cfg => {
      'return 301' => "https://${canonical_fqdn}\$request_uri",
    },
  }

  nginx::resource::location { 'forge-web web app root':
    priority            => 408,
    server              => 'forge-web',
    ssl                 => true,
    ssl_only            => true,
    location            => '/',
    www_root            => '/opt/forge-web/current/public',
    location_cfg_append => {
      'try_files' => '$uri/index.html $uri.html $uri @web',
    },
  }

  # caching
  nginx::resource::location { 'forge-web sitemap.xml cache':
    priority            => 430,
    server              => 'forge-web',
    ssl                 => true,
    ssl_only            => true,
    location_custom_cfg => {
      #'rewrite /sitemap.xml' => '/sitemap.xml? break', commented out incase we want to use it later.
      'proxy_cache'       => 'd2',
      'proxy_cache_valid' => '200 12h',
      'proxy_pass'        => 'http://unicorn-web',
    },
    location            => '/sitemap.xml',
  }
  nginx::resource::location { 'forge-web static cache':
    priority             => 431,
    ssl                  => true,
    ssl_only             => true,
    www_root             => '/opt/forge-web/current/public',
    location             => '~* \.(jpg|jpeg|png|gif|ico|css|js|eot|woff|svg|ttf|otf)$',
    server               => 'forge-web',
    location_cfg_prepend => {
      'expires'                  => 'max',
      'add_header Cache-Control' => 'public',
    },
  }

  with('forge-web-legacy') |$vhost| {
    nginx::resource::location { "${vhost} redirect to canonical":
      server              => $vhost,
      ssl                 => true,
      location            => '/',
      location_custom_cfg => {
        'return 301' => "https://${canonical_fqdn}\$request_uri",
      },
    }

    # Legacy web requests. They only need to be served from the old vhosts.
    nginx::resource::location { "${vhost} system releases legacy":
      priority            => 421,
      server              => $vhost,
      ssl                 => true,
      location_custom_cfg => {
        'rewrite ^/system/releases/([^\/]+)/([^\/]+)/([^\/]+)' => '/v3/files/$3 break',
        'include'                                              => '/etc/nginx/legacy-proxy.conf',
      },
      location            => '~ ^\/system\/releases\/(.+)',
    }
    nginx::resource::location { "${vhost} users legacy":
      priority            => 422,
      server              => $vhost,
      ssl                 => true,
      location_custom_cfg => {
        'rewrite ^/users/([^\/]+)/modules/([^\/]+)/releases/find\.json' => '/v1/users/$1/modules/$2/releases/find.json break',
        'include'                                                       => '/etc/nginx/legacy-proxy.conf',
      },
      location            => '~ ^\/users\/([^\/]+)\/modules\/([^\/]+)\/releases\/find\.json',
    }
    nginx::resource::location { "${vhost} api releases legacy":
      priority            => 423,
      server              => $vhost,
      ssl                 => true,
      location_custom_cfg => {
        'rewrite ^/api/v1/releases\.json' => '/v1/releases.json break',
        'include'                         => '/etc/nginx/legacy-proxy.conf',
      },
      location            => '= /api/v1/releases.json',
    }
    nginx::resource::location { "${vhost} json legacy":
      priority            => 424,
      server              => $vhost,
      ssl                 => true,
      location_custom_cfg => {
        'rewrite ^/([^\/]+)/([^\/]+)\.json' => '/v1/users/$1/modules/$2.json break',
        'include'                           => '/etc/nginx/legacy-proxy.conf',
      },
      location            => '~ ^\/([^\/]+)\/([^\/]+)\.json',
    }
    nginx::resource::location { "${vhost} modules.json legacy":
      priority            => 425,
      server              => $vhost,
      ssl                 => true,
      location_custom_cfg => {
        'rewrite ^/modules\.json' => '/v1/modules.json break',
        'include'                 => '/etc/nginx/legacy-proxy.conf',
      },
      location            => '= /modules.json',
    }
  }

  ['forge-web', 'forge-web-legacy'].each |$vhost| {
    nginx::resource::location { "${vhost} ping check web":
      server           => $vhost,
      location         => '^~ /ping',
      proxy_set_header => ['Host $host'],
      proxy            => 'http://unicorn-web',
    }

    # API Proxy for client-side JS
    nginx::resource::location { "${vhost} api proxy":
      priority            => 410,
      server              => $vhost,
      ssl                 => true,
      ssl_only            => true,
      location_custom_cfg => {
        'proxy_set_header Authorization' => '"Bearer $cookie_auth"',
        'include'                        => '/etc/nginx/legacy-proxy.conf',
      },
      location            => '~ ^\/(private|v3)\/',
    }

    nginx::resource::location { "${vhost} unicorn-web":
      ssl                 => true,
      ssl_only            => true,
      server              => $vhost,
      location            => '@web',
      proxy_redirect      => 'off',
      proxy               => 'http://unicorn-web',
      location_cfg_append => {
        proxy_set_header  => ['X-Request-Received $msec'],
      },
    }
  }

  logrotate::job { 'unicorn_forge-web':
    log        => "${app_root}/log/*.log",
    options    => [
      'maxsize 100M',
      'rotate 10',
      'weekly',
      'compress',
      'compresscmd /usr/bin/xz',
      'uncompresscmd /usr/bin/unxz',
      'compressext .xz',
      'notifempty',
      'sharedscripts',
      "create ${user} ${group}",
    ],
    postrotate => [
      "/bin/chown -R ${user}:${group} ${app_root}/log",
      '/etc/init.d/unicorn_forge-web reopen-logs > /dev/null',
    ],
    require    => Unicorn::App['forge-web'],
  }

  # Check Fact for environment type: (DEV, STAGE, PROD)
  if $facts['classification']['stage'] == 'prod' {
    #Add local rsyslog functionality
    include rsyslog
  }

  # Set up sending forge logs into logstash
  if $facts['classification']['stage'] == 'prod' {
    $file_name = 'production'
  }
  elsif $facts['classification']['stage'] == 'stage' {
    $file_name = 'staging'
  }

  # Forward logs via logstash
  ::logstashforwarder::file { 'forge-web':
    paths  => ["/opt/forge-web/log/${file_name}.log"],
    fields => { 'type' => 'vulcan' },
  }

  # If $acceptance_flag is set TRUE no need to do this
  # since it is handled by the LB
}
