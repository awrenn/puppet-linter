# == Class: profile::forgenext::web
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
class profile::forgenext::web (
  String[1]           $client_id,
  String[1]           $client_secret,
  String[1]           $session_secret,
  String[1]           $encryption_secret,
  String[1]           $statsd_svr,
  String[1]           $appsignal_frontend_api_key,
  Optional[String[1]] $old_session_secret = undef,
  String[1]           $web_domain = "https://${facts['classification']['group']}-web-${facts['classification']['stage']}.ops.puppetlabs.net", # override this in production
  Boolean             $enable_honeybadger = false,
  Boolean             $index = true,
  String[1]           $log_level = 'info',
  Integer             $unicorn_backlog = 16, # set very low so requests queue at the load balancer
) {
  include profile::server
  include profile::forgenext::shared
  include profile::forgenext::app
  include profile::nginx
  include ruby::dev
  include git
  include unicorn
  include libxslt1
  include libxml2

  # create the user, home directory, etc to run the forge-web application as
  $user            = 'forgeweb'
  $group           = 'forgeweb'
  $user_home       = '/var/lib/forgeweb'
  realize(Account::User[$user])
  realize(Group[$group])
  Ssh::Authorized_key <| tag == 'forgeweb-keys' |>
  ssh::allowgroup { 'forgeweb': }  # needed by harrison for deploys as that user
  sudo::allowgroup { 'forgeweb': } # needed by harrison for deploys as that user

  $apiserver       = profile::forgenext::vhost('api')
  $api_domain      = profile::forgenext::api_domain()
  $api_url         = 'http://127.0.0.1:8081'
  $app_root        = '/opt/forge-web'
  $next_app_root   = '/opt/forge-web-next'

  $host_group      = $facts['classification']['group']
  $host_stage      = $facts['classification']['stage']
  $host_domain     = $facts['networking']['domain']

  $statsd_prefix   = [
    $host_group,
    $host_stage,
    "${facts['classification']['function']}${facts['classification']['number_string']}",
    'web'
  ].join('.')

  $compress_mime_types = [
    'text/css',
    'text/javascript',
    'application/javascript',
    'text/plain',
    'text/xml',
    'application/json',
    'image/svg+xml',
  ]

  file { [ $app_root, "${app_root}/config", "${app_root}/log", "${app_root}/assets" ]:
    ensure => directory,
    owner  => $user,
    group  => $group,
  }

  file { "${app_root}/config/settings.yml":
    ensure  => file,
    owner   => $user,
    group   => $group,
    mode    => '0640',
    content => template('profile/forgenext/web/settings.yml.erb'),
    require => File["${app_root}/config"],
    notify  => Unicorn::App['forge-web'],
  }

  if $index {
    $robots_source = 'puppet:///modules/profile/forge/web/robots-index.txt'
  } else {
    $robots_source ='puppet:///modules/profile/forge/web/robots-noindex.txt'
  }

  file { "${app_root}/assets/robots.txt":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0644',
    source  => $robots_source,
    require => File["${app_root}/assets"],
  }

  $unicorn_socket  = "${user_home}/unicorn.sock"
  $unicorn_pidfile = "${user_home}/unicorn.pid"

  unicorn::app { 'forge-web':
    approot         => "${app_root}/current",
    workers         => $facts['processors']['count'],
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
      'HONEYBADGER_API_KEY'     => '9253e012',
      'HONEYBADGER_ENV'         => $host_stage,
      'HONEYBADGER_REPORT_DATA' => $enable_honeybadger,
    },
    require         => [
      File["${app_root}/config"],
      Class['ruby::dev'],
      Class['profile::forgenext::rbenv'],
    ],
  }

  # add CNAME for web vhost
  @@dns_record { profile::forgenext::vhost('web'):
    ensure  => present,
    domain  => 'ops.puppetlabs.net',
    content => $facts['networking']['fqdn'],
    type    => 'CNAME',
    ttl     => 900,
  }

  # add CNAME for web-react vhost
  @@dns_record { profile::forgenext::vhost('web-react'):
    ensure  => present,
    domain  => 'ops.puppetlabs.net',
    content => $facts['networking']['fqdn'],
    type    => 'CNAME',
    ttl     => 900,
  }

  # Nginx Configuration
  nginx::resource::server { 'forge-web':
    ensure               => present,
    listen_port          => 8080,
    server_name          => [
      'forge.puppet.com',
      'forge.puppetlabs.com',
      $facts['networking']['fqdn'],
      profile::forgenext::vhost('web'),
      "${host_group}-web-${host_stage}.${host_domain}",
      "forge-${host_stage}.puppet.com",
    ],
    use_default_location => false,
    www_root             => '/opt/forge-web/current/public',
    client_max_body_size => '10m',
    proxy_set_header     => [
      'X-Forwarded-For $proxy_add_x_forwarded_for',
      'X-Real-IP $remote_addr',
      'X-Forwarded-Proto $scheme',
      'Host $http_host',
    ],
    server_cfg_prepend   => {
      # extra access_log in combined format for awslogs ingestion
      'access_log'       => '/var/log/nginx/forge-web.access.combined.log combined',
    },
    access_log           => '/var/log/nginx/forge-web.access.log',
    format_log           => 'logstash_json',
    include_files        => [
      "${next_app_root}/current/nginx/*.conf",
      "${next_app_root}/current/nginx/${host_stage}/*.conf",
    ],
  }

  # vhost for direct access to forge-web next.js app
  nginx::resource::server { 'forge-web-react':
    ensure               => present,
    listen_port          => 8080,
    server_name          => [
      profile::forgenext::vhost('web-react'),
      "${host_group}-web-react-${host_stage}.${host_domain}",
    ],
    use_default_location => false,
    www_root             => '/opt/forge-web-next',
    autoindex            => 'off',
    index_files          => [],
    client_max_body_size => '10m',
    proxy_set_header     => [
      'X-Forwarded-For $proxy_add_x_forwarded_for',
      'X-Real-IP $remote_addr',
      'X-Forwarded-Proto $scheme',
      'Host $http_host',
    ],
    server_cfg_prepend   => {
      # extra access_log in combined format for awslogs ingestion
      'access_log'       => '/var/log/nginx/forge-web-react.access.combined.log combined',
    },
    access_log           => '/var/log/nginx/forge-web-react.access.log',
    format_log           => 'logstash_json',
    include_files        => [
      "${next_app_root}/current/nginx/*.conf",
      "${next_app_root}/current/nginx/${host_stage}/*.conf",
    ],
  }

  profile::forgenext::app::legacy_nginx_locations { 'forge-web legacy nginx locations':
    nginx_server => 'forge-web',
    require      => File['/etc/nginx/legacy-proxy.conf'],
  }

  nginx::resource::location { "${module_name} - ping check web":
    server           => 'forge-web',
    location         => '^~ /ping',
    proxy_set_header => ['Host $host'],
    proxy            => 'http://unicorn-web',
  }

  # API Proxy for client-side JS
  nginx::resource::location { "${module_name} - api proxy":
    server              => 'forge-web',
    location_custom_cfg => {
      'proxy_set_header Authorization' => '"Bearer $cookie_auth"',
      'include'                        => '/etc/nginx/legacy-proxy.conf',
    },
    location            => '~ ^\/(private|v3)\/',
    require             => File['/etc/nginx/legacy-proxy.conf'],
  }

  # Prefix match for any URI beginning with /continuous-delivery, used to regex match more
  # specific URIs and redirect from old Nebula content to the standalone site for Relay.
  nginx::resource::location { 'nebula content redirect':
    server              => 'forge-web',
    location_custom_cfg => {
      'rewrite ^/continuous-delivery\/?$'                                                                                                               => 'https://relay.sh/ permanent',
      'rewrite ^/continuous-delivery\/puppetlabs\/(run\-sample\-workflow|notify\-team\-with\-slack|deploy\-gatsby\-site\-to\-gcp\-with\-terraform)\/?$' => 'https://relay.sh/ permanent',
    },
    location            => '/continuous-delivery',
  }

  nginx::resource::location { "${module_name} - users legacy":
    server              => 'forge-web',
    location_custom_cfg => {
      'rewrite ^/users/([^\/]+)/modules/([^\/]+)/releases/find\.json' => '/v1/users/$1/modules/$2/releases/find.json break',
      'include'                                                       => '/etc/nginx/legacy-proxy.conf',
    },
    location            => '~ ^\/users\/([^\/]+)\/modules\/([^\/]+)\/releases\/find\.json',
    require             => File['/etc/nginx/legacy-proxy.conf'],
  }

  nginx::resource::location { "${module_name} - json legacy":
    server              => 'forge-web',
    location_custom_cfg => {
      'rewrite ^/([^\/]+)/([^\/]+)\.json' => '/v1/users/$1/modules/$2.json break',
      'include'                           => '/etc/nginx/legacy-proxy.conf',
    },
    location            => '~ ^\/([^\/]+)\/([^\/]+)\.json',
    require             => File['/etc/nginx/legacy-proxy.conf'],
  }

  # caching
  nginx::resource::location { "${module_name} - sitemap.xml cache":
    server              => 'forge-web',
    location_custom_cfg => {
      #'rewrite /sitemap.xml' => '/sitemap.xml? break', commented out incase we want to use it later.
      'proxy_cache'       => 'd2',
      'proxy_cache_valid' => '200 12h',
      'proxy_pass'        => 'http://unicorn-web',
    },
    location            => '/sitemap.xml',
  }

  file { '/etc/nginx/unicorn-proxy.conf':
    ensure => present,
    source => 'puppet:///modules/profile/forgenext/web/forge-unicorn-proxy.conf',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Service['nginx'],
  }

  nginx::resource::location { "${module_name} - default web":
    server              => 'forge-web',
    location            => '/',
    location_custom_cfg => {
      'include' => '/etc/nginx/unicorn-proxy.conf',
    },
    require             => File['/etc/nginx/unicorn-proxy.conf'],
  }

  # Static assets - first checks legacy forge web app before moving on to the next.js app
  nginx::resource::location { "${module_name} - static cache":
    www_root            => '/opt',
    location            => '~* ^(?!/_next/)(.*\.(jpg|jpeg|png|gif|ico|css|js|eot|woff|svg|ttf|otf))$',
    server              => 'forge-web',
    index_files         => [],
    try_files           => [
      '/forge-web/current/public/$1',
      '/forge-web-next/current/public/$1',
      '/forge-web-next/previous/public/$1',
    ],
    location_custom_cfg => {
      'expires'                  => 'max',
      'add_header Cache-Control' => 'public',
      'gzip'                     => 'on',
      'gzip_types'               => join($compress_mime_types, ' '),
      'gzip_min_length'          => '1024',
    },
  }

  nginx::resource::location { "${module_name} - next.js static assets":
    server              => 'forge-web',
    location            => '~* ^/_next/static/(.*)$',
    autoindex           => 'off',
    index_files         => [],
    www_root            => $next_app_root,
    try_files           => [
      '/current/.next/static/$1',
      '/previous/.next/static/$1',
      '@next',
    ],
    location_custom_cfg => {
      'expires'                  => 'max',
      'add_header Cache-Control' => 'public',
      'gzip'                     => 'on',
      'gzip_types'               => join($compress_mime_types, ' '),
      'gzip_min_length'          => '1024',
    },
  }

  nginx::resource::location { "${module_name} - next.js data loading":
    server      => 'forge-web',
    location    => '~* ^/_next/data/(.*)$',
    autoindex   => 'off',
    index_files => [],
    www_root    => $next_app_root,
    try_files   => [
      '/dev/null',
      '@next',
    ],
  }

  $socket = "unix:${unicorn_socket}"
  nginx::resource::upstream { "${module_name} - unicorn-web":
    name        => 'unicorn-web',
    members     => {
      "${socket}" => {
        server       => $socket,
        fail_timeout => '0',
      },
    },
    cfg_prepend => {
      'keepalive'         => '10',
    },
  }

  nginx::resource::upstream { "${module_name} - nextjs-upstream":
    name        => 'nextjs-web',
    members     => {
      'localhost:8100' => {
        server => 'localhost',
        port   => 8100,
      },
    },
    cfg_prepend => {
      'keepalive' => '10',
    },
  }

  nginx::resource::location { "${module_name} - nextjs-proxy":
    server              => 'forge-web',
    location            => '@next',
    proxy_redirect      => 'off',
    proxy               => 'http://nextjs-web',
    location_cfg_append => {
      proxy_set_header  => ['X-Request-Received $msec'],
    },
  }

  nginx::resource::location { "${module_name}-react - nextjs-proxy":
    server              => 'forge-web-react',
    location            => '@next',
    proxy_redirect      => 'off',
    proxy               => 'http://nextjs-web',
    location_cfg_append => {
      proxy_set_header  => ['X-Request-Received $msec'],
    },
  }

  nginx::resource::location { "${module_name}-react - default web":
    server      => 'forge-web-react',
    location    => '/',
    autoindex   => off,
    index_files => [],
    try_files   => [
      '/dev/null',
      '@next',
    ],
  }

  nginx::resource::location { "${module_name}-react - next.js static assets":
    server              => 'forge-web-react',
    location            => '~* ^/_next/static/(.*)$',
    autoindex           => 'off',
    index_files         => [],
    try_files           => [
      '/current/.next/static/$1',
      '/previous/.next/static/$1',
      '@next',
    ],
    location_custom_cfg => {
      'expires'                  => 'max',
      'add_header Cache-Control' => 'public',
      'gzip'                     => 'on',
      'gzip_types'               => join($compress_mime_types, ' '),
      'gzip_min_length'          => '1024',
    },
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
      '/bin/systemctl kill -s USR1 --kill-who=main unicorn_forge-web.service',
    ],
  }

  # nodejs app for new forge-web
  class { 'profile::nodejs':
    # nodesource apt repos only include the latest minor version in the Packages index
    # so we can't pin to an exact version and ensure that newly deployed servers will be
    # able to easily get it. So for now we will just ensure latest (of the major version
    # specified using the `deb_node_source` param) and rely on Puppet to keep all the app
    # servers on an eventually consistent version.
    package_version => 'latest',
    deb_node_source => 'https://deb.nodesource.com/node_14.x',
  }

  # N.B. A hard restart of the forge-web-pm2 service is necessary for downgrading versions.
  # In that scenario, it seems that the reload performed does not delete the running processes,
  # so the changed version is not utilized when the existing processes restart. The Forge Bolt
  # task `forge::hard_restart_pm2` or `forge::safe_task` plan in the forge-infra repo may be used
  # to hard restart pm2.
  package { 'pm2':
    ensure   => '4.5.0',
    provider => 'npm',
    require  => Class['profile::nodejs'],
  }

  file { [ $next_app_root, "${next_app_root}/config", "${next_app_root}/log" ]:
    ensure => directory,
    owner  => $user,
    group  => $group,
  }

  $appsignal_app_env = $host_stage ? {
    'prod'  => 'production',
    'stage' => 'staging',
    default => 'development',
  }
  $appsignal_push_api_key = unwrap(lookup('profile::forgenext::shared::sensitive_appsignal_key'))
  $appsignal_working_directory_path = '/tmp/appsignal_forge_web'

  file { "${next_app_root}/config/forge-web.config.js":
    ensure  => file,
    owner   => $user,
    group   => $group,
    mode    => '0640',
    content => epp('profile/forgenext/web/forge-web.config.js.epp', {
      'api_domain'                       => $api_domain,
      'appsignal_app_env'                => $appsignal_app_env,
      'appsignal_frontend_api_key'       => $appsignal_frontend_api_key,
      'appsignal_push_api_key'           => $appsignal_push_api_key,
      'appsignal_working_directory_path' => $appsignal_working_directory_path,
      'basedir'                          => $next_app_root,
      'client_id'                        => $client_id,
      'client_secret'                    => $client_secret,
      'web_domain'                       => $web_domain,
      'instances'                        => 2,
      'port'                             => 8100,
    }),
    require => File["${next_app_root}/config"],
    notify  => Service['forge-web-pm2'],
  }

  systemd::unit_file { 'forge-web-pm2.service':
    content => epp('profile/forgenext/web/forge-web-pm2.service.epp', {
      'user'            => $user,
      'base_dir'        => $next_app_root,
      'pm2_config_file' => "${next_app_root}/config/forge-web.config.js",
    }),
    require => Package['pm2'],
  }

  service { 'forge-web-pm2':
    ensure    => running,
    enable    => true,
    require   => [
      File["${next_app_root}/config/forge-web.config.js"],
      Systemd::Unit_file['forge-web-pm2.service'],
    ],
    subscribe => [
      Systemd::Unit_file['forge-web-pm2.service'],
      Class['profile::nodejs'],
    ],
  }

  logrotate::job { 'nodejs_forge-web-next':
    log        => "${next_app_root}/log/*.log",
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
      "/bin/chown -R ${user}:${group} ${next_app_root}/log",
      # https://pm2.keymetrics.io/docs/usage/log-management/#reloading-all-logs
      '/bin/systemctl kill -s USR2 --kill-who=main forge-web-pm2.service',
    ],
  }

  if $profile::server::logging {
    if Integer($facts['os']['release']['major']) < 10 {
      include profile::logging::logstashforwarder

      logstashforwarder::file { "${module_name} - forge-web":
        paths  => ['/opt/forge-web/log/forge-web.log'],
        fields => {
          'type' => 'vulcan',
        },
      }
    } else {
      include profile::aws::cloudwatch

      cloudwatch::log { '/opt/forge-web/log/main.log':
        datetime_format => '%Y-%m-%d %H:%M:%S %z',
      }

      # TODO: add next.js logs to cloudwatch
    }
  }
}
