# == Class: profile::forge::api
#
# Gerenal profile class for createing Forge Web Service Instances.
#
# === Authors
#
#  Puppet Ops <opsteam@puppetlabs.com>
#
# === Copyright
#
# Copyright 2014 Puppet Labs, unless otherwise noted.
#
class profile::forgenext::api (
  String[1]            $bcrypt_secret,
  String[1]            $statsd_svr,
  String[1]            $sendgrid_key,  # api key for sending mail thru sendgrid
  String[1]            $github_token,  # Github token to read and serve certain private files
  String[1]            $db_host,
  String[1,63]         $db_name, # postgresql identifiers can only be 64 chars
  String[1,63]         $db_user, # postgresql identifiers can only be 64 chars
  String[1]            $db_password,
  Sensitive[String[1]] $sensitive_pre_shared_key, # pre-shared key for private endpoints
  String[1]            $amazon_bucket       = "${facts['classification']['group']}-modules-${facts['classification']['stage']}",
  String[1]            $backup_bucket       = "${facts['classification']['group']}-modules-${facts['classification'][stage]}-backup",
  String[1]            $amazon_region       = 'us-west-2',
  String[1]            $web_location        = "https://${facts['classification']['group']}-web-${facts['classification']['stage']}.ops.puppetlabs.net", # override this in production
  String[1]            $api_location        = "https://${facts['classification']['group']}-api-${facts['classification']['stage']}.ops.puppetlabs.net", # override this in production
  Boolean              $enable_honeybadger  = false,
  Boolean              $enable_appsignal    = true,
  String[1]            $log_level           = 'info',
  Integer              $unicorn_backlog     = 16, # set very low so requests queue at the load balancer
  # credentials for these should be provided by IAM instance profiles now
  Optional[Sensitive[String[1]]] $sensitive_anubis_aws_key    = undef,
  Optional[Sensitive[String[1]]] $sensitive_anubis_aws_secret = undef,
  Optional[Sensitive[String[1]]] $sensitive_s3_aws_key        = undef,
  Optional[Sensitive[String[1]]] $sensitive_s3_aws_secret     = undef,
) {
  $vhost           = $facts['networking']['hostname']
  $servername      = $vhost
  $app_root        = '/opt/forge-api'
  $backend         = 'S3'
  $statsd_prefix   = "${facts['classification']['group']}.${facts['classification']['stage']}.${facts['classification']['function']}${facts['classification']['number_string']}.api" # lint:ignore:140chars

  include profile::server
  include profile::forgenext::shared
  include profile::forgenext::app
  include profile::nginx
  include ruby::dev
  include libxslt1
  include libxml2
  include unicorn

  ensure_packages(['jq', 'libjq-dev'], {'ensure' => 'latest'})

  $user      = 'forgeapi'
  $group     = 'forgeapi'
  $user_home = '/var/lib/forgeapi'
  realize(Account::User[$user])
  realize(Group[$group])
  Ssh::Authorized_key <| tag == 'forgeapi-keys' |>

  ssh::allowgroup { 'forgeapi': }  # needed by harrison for deploys as that user
  sudo::allowgroup { 'forgeapi': } # needed by harrison for deploys as that user

  $unicorn_socket  = "${user_home}/unicorn.sock"
  $unicorn_pidfile = "${user_home}/unicorn.pid"

  $appsignal_push_api_key = unwrap(lookup('profile::forgenext::shared::sensitive_appsignal_key'))
  $appsignal_app_name = 'Forge API'
  $appsignal_app_env = "aws-${facts['classification']['stage']}"
  $appsignal_working_directory_path = '/tmp/appsignal_forge_api/'

  unicorn::app { 'forge-api':
    approot         => "${app_root}/current",
    workers         => ($facts['processors']['count'] + 2),
    pidfile         => $unicorn_pidfile,
    socket          => $unicorn_socket,
    user            => $user,
    group           => $group,
    config_file     => "${app_root}/config/forge-unicorn.rb",
    config_template => 'profile/forgenext/unicorn_config.rb.erb',
    preload_app     => true,
    rack_env        => 'main',
    source          => '/usr/local/rbenv/shims/ruby ./bin/unicorn',
    init_time       => 120,
    backlog         => $unicorn_backlog,
    extra_settings  => {
      'NEWRELIC_AGENT_ENABLED'           => false,
      'HONEYBADGER_API_KEY'              => '812b15d9',
      'HONEYBADGER_ENV'                  => $facts['classification']['stage'],
      'HONEYBADGER_REPORT_DATA'          => $enable_honeybadger,
      'APPSIGNAL_PUSH_API_KEY'           => $appsignal_push_api_key,
      'APPSIGNAL_APP_NAME'               => $appsignal_app_name,
      'APPSIGNAL_APP_ENV'                => $appsignal_app_env,
      'APPSIGNAL_ACTIVE'                 => $enable_appsignal,
      # Since the main Unicorn process starts as root, ensure the Appsignal agent files are set to
      # Unix permissions 666 so the forgeapi user may access files written by root.
      'APPSIGNAL_FILES_WORLD_ACCESSIBLE' => true,
      'APPSIGNAL_IGNORE_ACTIONS'         => 'GET /ping',
      'APPSIGNAL_IGNORE_ERRORS'          => 'Sinatra::NotFound,Aws::Errors::MissingCredentialsError',
      'APPSIGNAL_WORKING_DIRECTORY_PATH' => $appsignal_working_directory_path,
      'FORGE_API_PRE_SHARED_KEY'         => unwrap($sensitive_pre_shared_key),
      'FORGE_API_API_LOCATION'           => $api_location,
    },
    require         => [
      File["${app_root}/config"],
      Class['ruby::dev'],
      Class['profile::forgenext::rbenv'],
    ],
  }

  file { [ $app_root, "${app_root}/config", "${app_root}/log", "${app_root}/assets" ]:
    ensure => directory,
    owner  => $user,
    group  => $group,
  }

  file { "${app_root}/config/settings.yml":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0640',
    content => template('profile/forgenext/api/settings.yml.erb'),
    require => File["${app_root}/config"],
    notify  => Unicorn::App['forge-api'],
  }

  file { '/etc/systemd/system/forge_que.service':
    ensure    => present,
    owner     => root,
    group     => root,
    mode      => '0644',
    content   => epp('profile/forgenext/api/forge_que.service.epp', {
      'user'                             => $user,
      'group'                            => $group,
      'working_dir'                      => '/opt/forge-api/current',
      'rack_env'                         => 'main',
      'aws_key'                          => $sensitive_anubis_aws_key,
      'aws_secret'                       => $sensitive_anubis_aws_secret,
      'api_location'                     => $api_location,
      'appsignal_push_api_key'           => $appsignal_push_api_key,
      'appsignal_app_name'               => $appsignal_app_name,
      'appsignal_app_env'                => $appsignal_app_env,
      'appsignal_working_directory_path' => $appsignal_working_directory_path,
    }),
    notify    => [
      Service['forge_que'],
      Exec['forge_que reload systemd'],
    ],
    show_diff => false,
  }

  service { 'forge_que':
    ensure  => running,
    enable  => true,
    require => [
      File['/etc/systemd/system/forge_que.service'],
      Exec['forge_que reload systemd'],
      File["${app_root}/config/settings.yml"],
    ],
  }

  exec { 'forge_que reload systemd':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  file { "${app_root}/assets/robots.txt":
    ensure => present,
    owner  => $user,
    group  => $group,
    mode   => '0644',
    source => 'puppet:///modules/profile/forge/api/robots-prod.txt',
  }

  # since each app server has both a web vhost and an api vhost, we need two
  # CNAMEs so you can actually access them.
  @@dns_record { profile::forgenext::vhost('api'):
    ensure  => present,
    domain  => 'ops.puppetlabs.net',
    content => $facts['networking']['fqdn'],
    type    => 'CNAME',
    ttl     => 900,
  }


  nginx::resource::server { 'forge-api':
    ensure               => present,
    listen_port          => 8080,
    use_default_location => false,
    www_root             => '/opt/forge-api/current/public',
    client_max_body_size => '15m',
    server_cfg_prepend   => {
      'listen'                 => '127.0.0.1:8081',
      'proxy_intercept_errors' => 'on',
      'error_page 404'         => '/404.json',
      'error_page 413'         => '/413.json',
      'error_page 500'         => '/500.json',
      'error_page 502'         => '/502.json',
      # extra access_log in combined format for awslogs ingestion
      'access_log'             => '/var/log/nginx/forge-api.access.combined.log combined',
    },
    server_name          => [
      'forgeapi.puppet.com',
      '~forgeapi-(new|old)\.puppet\.com',
      'forgeapi.puppetlabs.com',
      "forgeapi-${facts['classification']['stage']}.puppet.com",
      profile::forgenext::vhost('api'),
      "${facts['classification']['group']}-api-${facts['classification']['stage']}.${facts['networking']['domain']}",
      '~api',
    ],
    access_log           => '/var/log/nginx/forge-api.access.log',
    format_log           => 'logstash_json',
  }

  # Adds support for legacy locations and clients such as Puppet Module Tool versions <= 3.8
  profile::forgenext::app::legacy_nginx_locations { 'forge-api legacy nginx locations':
    nginx_server => 'forge-api',
    require      => File['/etc/nginx/legacy-proxy.conf'],
  }

  nginx::resource::location { "api ping check - ${module_name}":
    server               => 'forge-api',
    location             => '= /ping',
    proxy_set_header     => ['Host $host'],
    proxy                => 'http://unicorn-api',
    location_cfg_prepend => {
      'add_header' => 'X-Forwarded-By $hostname',
    },
  }

  nginx::resource::location { "api app root - ${module_name}":
    server              => 'forge-api',
    location            => '/',
    www_root            => '/opt/forge-api/current/public',
    location_cfg_append => {
      'try_files'  => '$uri/index.html $uri.html $uri @api',
    },
  }

  nginx::resource::location { "releases v1 cache - ${module_name}":
    server              => 'forge-api',
    location_custom_cfg => {
      'proxy_cache'          => 'd2',
      'proxy_cache_key'      => '"$scheme$proxy_host$request_uri $http_accept_encoding"',
      'proxy_ignore_headers' => '"Cache-Control"',
      'proxy_cache_valid'    => '200 15m',
      'proxy_pass'           => 'http://unicorn-api',
    },
    location            => '^~ /v1/releases',
  }

  nginx::resource::location { "error pages - ${module_name}":
    server   => 'forge-api',
    internal => true,
    location => '~ ^/[4-5][0-1][0-9]\.json$',
  }

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

  nginx::resource::location { "unicorn-api - ${module_name}":
    server           => 'forge-api',
    location         => '@api',
    proxy_set_header => ['X-Forwarded-For $proxy_add_x_forwarded_for', 'X-Real-IP $remote_addr', 'X-Forwarded-Proto $scheme', 'Host $http_host', 'X-Request-Received $msec'], # lint:ignore:140chars
    proxy_redirect   => 'off',
    proxy            => 'http://unicorn-api',
  }

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
      'delaycompress',
      "create ${user} ${group}",
    ],
    postrotate => [
      "/bin/chown -R ${user}:${group} ${app_root}/log",
      '/bin/systemctl kill -s USR1 --kill-who=main unicorn_forge-api.service',
      '/bin/systemctl restart forge_que > /dev/null',
    ],
  }

  if $profile::server::logging {
    if Integer($facts['os']['release']['major']) < 10 {
      include profile::logging::logstashforwarder

      logstashforwarder::file { 'forge-api':
        paths  => ['/opt/forge-api/log/forge-api.log'],
        fields => { 'type' => 'vulcan' },
      }
    } else {
      include profile::aws::cloudwatch

      cloudwatch::log { '/opt/forge-api/log/main.log':
        datetime_format => '%Y-%m-%d %H:%M:%S %z',
      }
    }
  }
}
