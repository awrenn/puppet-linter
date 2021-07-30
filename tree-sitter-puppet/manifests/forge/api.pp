# == Class: profile::forge::api
#
# Gerenal profile class for createing Forge Web Service Instances.
# Special attention should be given to the $acceptance_flag as it triggers
# specific funtionality in the model.  It enable the use of this profile
# in a Forge Acceptance instance.  Setting this value to true in hiera allows
# simultaneous use with the Forage Web Application.
# It basically allows for one of two scenarios:
# - Simultaneous coexistance with the Forge Web Application
# - Standalone functinality
#
# === Authors
#
#  Puppet Ops <opsteam@puppetlabs.com>
#
# === Copyright
#
# Copyright 2014 Puppet Labs, unless otherwise noted.
#
class profile::forge::api (
  $db_user             = undef,
  $db_password         = undef,
  $db_host             = undef,
  $db_name             = undef,
  $bcrypt_secret       = undef,
  $user                = 'forge-api',
  $group               = 'forge-api',
  $source              = 'git@github.com:puppetlabs/puppet-forge-api',
  $app_root            = '/opt/forge-api',
  $user_home           = '/var/lib/forge-api',
  $manageuser          = true,
  $newrelic_key        = '511674b2125d79323ea0605d1ab63617867cbefe',
  $exceptional_api_key = '3433f4aa7200698df949ac111b1c541e3575d2dc',
  $rack_env            = 'production',
  $statsd_svr          = '127.0.0.1:8125',
  $unicorn_workers     = '16',
  $log_level           = undef,
  $vhost               = $facts['networking']['hostname'],
  $files               = false,
  $backend             = 'S3',
  $amazon_secret       = undef,
  $amazon_id           = undef,
  $amazon_bucket       = undef,
  $backup_bucket       = undef,
  $amazon_region       = 'us-west-2',
  $web_location        = 'https://forge.puppet.com',
  $elasticsearch_url   = undef,
  $sendgrid_key        = undef,
  $acceptance_flag     = false,
  $acceptance_type     = 'aio',
  $acceptance_aliases  = [ "api-${facts['networking']['fqdn']}" ],
  $nginx_port          = '80',
  $nginx_sslport       = '443',
  $statsd_prefix       = "${facts['classification']['group']}.${facts['classification']['stage']}.${facts['classification']['function']}${facts['classification']['number_string']}.api", # lint:ignore:140chars
  String[1] $canonical_fqdn = "api-${facts['networking']['fqdn']}",
  Array[String[1]] $legacy_hostnames = [],
) {
  profile_metadata::service { $title:
    human_name        => 'Forge API Server',
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
  # validate_array($acceptance_aliases)
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

  # Required pacakages
  package { [ 'libpq-dev', 'libxml2' ]:
    ensure => 'present',
  }


  # Other includes
  include libxslt1
  include libxml2
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
      comment    => 'Puppet Labs API',
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

  include unicorn

  $unicorn_socket  = "${user_home}/unicorn.sock"
  $unicorn_pidfile = "${user_home}/unicorn.pid"

  # Gem dependency from the plops s3 repo.
  if $facts['os']['distro']['codename'] == 'wheezy' {
    package { 'forge-jq': ensure => 'present' }
  } else {
    ensure_packages(['jq'], {'ensure' => 'latest'})
    ensure_packages(['libjq-dev'], {'ensure' => 'present'})
  }

  unicorn::app { 'forge-api':
    approot         => "${app_root}/current",
    workers         => $unicorn_workers,
    pidfile         => $unicorn_pidfile,
    socket          => $unicorn_socket,
    user            => $user,
    group           => $group,
    config_file     => "${app_root}/config/forge-unicorn.rb",
    config_template => 'profile/forge/api/unicorn_config.rb.erb',
    preload_app     => true,
    rack_env        => $rack_env,
    source          => '/usr/local/rbenv/shims/ruby ./bin/unicorn',
    init_time       => 120,
    extra_settings  => {
      'NEWRELIC_AGENT_ENABLED' => false,
    },
    require         => [
      File["${app_root}/config"],
      Class['ruby::dev'],
      Class['profile::forge::rbenv'],
    ],
    subscribe       => Service['postgresql'],
  }

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

  file { "${app_root}/config/settings.yml":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0640',
    content => template('profile/forge/api/settings.yml.erb'),
    require => File["${app_root}/config"],
    notify  => Unicorn::App['forge-api'],
  }

  file { "${app_root}/config/newrelic.yml":
    ensure  => file,
    owner   => $user,
    group   => $group,
    mode    => '0640',
    content => template('profile/forge/api/newrelic.yml.erb'),
    require => File["${app_root}/config"],
    notify  => Unicorn::App['forge-api'],
  }

  file { "${app_root}/config/exceptional.yml":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0640',
    content => template('profile/forge/api/exceptional.yml.erb'),
    require => File["${app_root}/config"],
    notify  => Unicorn::App['forge-api'],
  }

  $robotstxt = $facts['classification']['stage'] ? {
    'prod'  => 'puppet:///modules/profile/forge/api/robots-prod.txt',
    default => 'puppet:///modules/profile/forge/robots-disallow-all.txt',
  }

  file { "${app_root}/assets/robots.txt":
    ensure => present,
    owner  => $user,
    group  => $group,
    mode   => '0644',
    source => $robotstxt,
  }

  # Acceptance Settings:
  if $acceptance_flag {
    # Check the accpetance instance type:
    # - AIO = All-In-One
    # - VulcanAPI
    if $acceptance_type == 'aio'{
      $servername = "${vhost}-api"
    } else {
      $servername = $vhost
    }
  } else {
    $servername = $vhost
  }

  # Nginx Configuration:
  include profile::nginx

  $socket = "unix:${unicorn_socket}"
  nginx::resource::upstream { 'unicorn-api':
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

  # Always include forgeapi.puppetlabs.com as a legacy hostname. Often internal
  # systems access non-production forge using that hostname.
  $all_legacy_hostnames = unique($legacy_hostnames + [ 'forgeapi' ])

  ssl::cert { 'forgeapi.puppet.com': }

  # Public end point Start
  nginx::resource::server {
    default:
      ensure               => present,
      use_default_location => false,
      listen_port          => scanf($nginx_port, '%i')[0],
      ssl                  => true,
      ssl_port             => scanf($nginx_sslport, '%i')[0],
      www_root             => '/opt/forge-api/current/public',
      client_max_body_size => '15m',
      access_log           => '/var/log/nginx/forgestagingapi.puppetlabs.com.access.log',
      format_log           => 'logstash_json',
      server_cfg_prepend   => {
        'proxy_intercept_errors' => 'on',
        'error_page 404'         => '/404.json',
        'error_page 413'         => '/413.json',
        'error_page 500'         => '/500.json',
        'error_page 502'         => '/502.json',
      },
    ;
    'forge-api':
      server_name => [ $canonical_fqdn, 'forgeapi.puppet.com' ].unique(),
      ssl_cert    => '/etc/ssl/certs/forgeapi.puppet.com_combined.crt',
      ssl_key     => '/etc/ssl/private/forgeapi.puppet.com.key',
    ;
    'forge-api-legacy':
      server_name    => $all_legacy_hostnames.map |$h| { "${h}.puppetlabs.com" },
      listen_options => 'default_server',
      ssl_cert       => '/etc/ssl/certs/forgeapi.puppet.com_combined.crt',
      ssl_key        => '/etc/ssl/private/forgeapi.puppet.com.key',
    ;
  }

  ['forge-api', 'forge-api-legacy'].each |$vhost| {
    nginx::resource::location { "${vhost} - default SSL redirect":
      server              => $vhost,
      location            => '/',
      location_custom_cfg => {
        'return 301' => "https://${canonical_fqdn}\$request_uri",
      },
    }

    nginx::resource::location { "${vhost} releases v1 cache":
      priority            => 408,
      server              => $vhost,
      ssl                 => true,
      ssl_only            => true,
      location_custom_cfg => {
        'proxy_cache'          => 'd2',
        'proxy_cache_key'      => '"$scheme$proxy_host$request_uri $http_accept_encoding"',
        'proxy_ignore_headers' => '"Cache-Control"',
        'proxy_cache_valid'    => '200 15m',
        'proxy_pass'           => 'http://unicorn-api',
      },
      location            => '^~ /v1/releases',
    }

    nginx::resource::location { "${vhost} api app root":
      priority            => 407,
      server              => $vhost,
      ssl                 => true,
      ssl_only            => true,
      location            => '/',
      www_root            => '/opt/forge-api/current/public',
      location_cfg_append => {
        'try_files' => '$uri/index.html $uri.html $uri @api',
      },
    }

    nginx::resource::location { "${vhost} api ping check":
      priority             => 406,
      server               => $vhost,
      location             => '= /ping',
      proxy_set_header     => ['Host $host'],
      proxy                => 'http://unicorn-api',
      location_cfg_prepend => {
        'add_header' => 'X-Forwarded-By $hostname',
      },
    }

    nginx::resource::location { "${vhost} error pages":
      ssl      => true,
      internal => true,
      location => '= /[4-5][0-1][0-9].json',
      server   => $vhost,
    }

    nginx::resource::location { "${vhost} unicorn-api":
      ssl              => true,
      ssl_only         => true,
      server           => $vhost,
      location         => '@api',
      proxy_set_header => ['X-Forwarded-For $proxy_add_x_forwarded_for', 'X-Real-IP $remote_addr', 'X-Forwarded-Proto $scheme', 'Host $http_host', 'X-Request-Received $msec'], # lint:ignore:140chars
      proxy_redirect   => 'off',
      proxy            => 'http://unicorn-api',
    }
  }

  with('forge-api-legacy') |$vhost| {
    nginx::resource::location { "${vhost} - redirect / to canonical host":
      server              => $vhost,
      ssl                 => true,
      ssl_only            => true,
      location            => '=/',
      location_custom_cfg => {
        'return 301' => "https://${canonical_fqdn}/",
      },
    }
  }
  # Public end point End

  # Interal end point Start
  nginx::resource::server { 'internal':
    ensure               => present,
    use_default_location => false,
    server_name          => ['forge-api', 'forge-api-legacy', '~api'],
    listen_ip            => '127.0.0.1',
    listen_port          => scanf($nginx_port, '%i')[0],
    www_root             => '/opt/forge-api/current/public',
    client_max_body_size => '15m',
    access_log           => '/var/log/nginx/forgestagingapi.puppetlabs.com-internal.access.log',
    format_log           => 'logstash_json',
    server_cfg_prepend   => {
      'proxy_intercept_errors' => 'on',
      'error_page 404'         => '/404.json',
      'error_page 413'         => '/413.json',
      'error_page 500'         => '/500.json',
      'error_page 502'         => '/502.json',
    },
  }

  nginx::resource::location { 'unicorn-api internal':
    server           => 'internal',
    location         => '@api',
    proxy_set_header => ['X-Forwarded-For $proxy_add_x_forwarded_for', 'X-Real-IP $remote_addr', 'X-Forwarded-Proto $scheme', 'Host $http_host', 'X-Request-Received $msec'], # lint:ignore:140chars
    proxy_redirect   => 'off',
    proxy            => 'http://unicorn-api',
  }

  nginx::resource::location { 'api app root internal':
    server              => 'internal',
    location            => '/',
    www_root            => '/opt/forge-api/current/public',
    location_cfg_append => {
      'try_files' => '$uri/index.html $uri.html $uri @api',
    },
  }

  nginx::resource::location { 'releases v1 cache internal':
    priority            => 401,
    server              => 'internal',
    location_custom_cfg => {
      'proxy_cache'          => 'd2',
      'proxy_cache_key'      => '"$scheme$proxy_host$request_uri $http_accept_encoding"',
      'proxy_ignore_headers' => '"Cache-Control"',
      'proxy_cache_valid'    => '200 15m',
      'proxy_pass'           => 'http://unicorn-api',
    },
    location            => '^~ /v1/releases',
  }

  nginx::resource::location { 'error pages internal':
    internal => true,
    location => '= /[4-5][0-1][0-9].json',
    server   => 'internal',
  }
  # End internal end point


  # Rotation job, so production.log doesn't get out of control!
  logrotate::job { 'unicorn_forge-api':
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
      '/etc/init.d/unicorn_forge-api reopen-logs > /dev/null',
    ],
    require    => Unicorn::App['forge-api'],
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

  logstashforwarder::file { 'forge-api':
    paths  => ["/opt/forge-api/log/${file_name}.log"],
    fields => { 'type' => 'vulcan' },
  }

}
