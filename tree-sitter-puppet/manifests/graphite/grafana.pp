#
# Class used to install grafana from upstream apt repo
# and configure the service and nginx
#
class profile::graphite::grafana (
  String[1] $access_key_id,
  String[1] $secret_access_key,
  $db_host        = '127.0.0.1',
  $db_password    = 'password',
  $admin_password = 'admin',
  $region         = 'us-west-2',
) {

  apt::source { 'grafana':
    location => 'https://packagecloud.io/grafana/stable/debian',
    include  => {
      'src' => false,
    },
    key      => {
      'server' => 'https://packagecloud.io',
      'id'     => '418A7F2FB0E1E6E7EABF6FE8C2E73424D59097AB',
    },
  }
  -> class { '::grafana':
    cfg => {
        server            => {
          http_addr      => '127.0.0.1',
          http_port      => 3030,
          protocol       => 'http',
          router_logging => true,
        },
        database          => {
          'type'   => 'postgres',
          host     => "${db_host}:5432",
          name     => 'grafana',
          user     => 'grafana',
          password => $db_password,
          path     => '',
        },
        users             => {
          allow_sign_up => false,
        },
        'auth.anonymous'  => {
          enabled  => true,
          org_role => 'Editor',
        },
        session           => {
          provider        => 'memcache',
          provider_config => '127.0.0.1:11211',
        },
        security          => {
          admin_password => $admin_password,
        },
        'dashboards.json' => {
          enabled => true,
          path    => '/var/lib/grafana/dashboards/',
        },
      },
  }

  # JSON Dashboards
  file { '/var/lib/grafana/dashboards':
    ensure  => directory,
    mode    => '0750',
    owner   => 'grafana',
    group   => 'grafana',
    recurse => true,
    purge   => true,
    force   => true,
    source  => 'puppet:///modules/profile/graphite/grafana/dashboards',
  }

  # Scripted Dashboards
  $rootdir = '/usr/share/grafana/public/dashboards'

  $dashboards = [
    'devhost',
  ]

  $dashboards.each |$dashboard| {
    file { "${rootdir}/${dashboard}.js":
      ensure => file,
      source => "puppet:///modules/profile/graphite/${dashboard}.js",
    }
  }

  # AWS CLoudwatch credentials
  include profile::aws::cli

  file { '/usr/share/grafana/.aws':
    ensure => directory,
    mode   => '0700',
    owner  => 'grafana',
    group  => 'grafana',
  }

  file { '/usr/share/grafana/.aws/credentials':
    ensure  => present,
    mode    => '0400',
    owner   => 'grafana',
    group   => 'grafana',
    content =>  template('profile/aws/credentials.erb'),
    require => File['/usr/share/grafana/.aws'],
  }

  # Nginx configs to handle removing the port number
  # We have so many ports to allow people with grafana 1 and grafana 2
  # bookmarks to still work properly.

  $return_config = {
    'return' => '301 $scheme://grafana.ops.puppetlabs.net$request_uri',
  }

  nginx::resource::server { 'grafana':
    ensure                => present,
    listen_port           => 80,
    server_name           => ['grafana.ops.puppetlabs.net'],
    proxy                 => 'http://127.0.0.1:3030/',
    proxy_read_timeout    => '60',
    proxy_connect_timeout => '10',
    proxy_set_header      => ['X-Real-IP $remote_addr', 'Host $http_host'],
    proxy_redirect        => 'off',
  }
  nginx::resource::server { 'grafana-3000':
    ensure               => present,
    listen_port          => 3000,
    server_name          => ['grafana.ops.puppetlabs.net'],
    use_default_location => false,
    server_cfg_prepend   => $return_config,
  }
  nginx::resource::server { 'grafana-8080':
    ensure               => present,
    listen_port          => 8080,
    server_name          => ['grafana.ops.puppetlabs.net'],
    use_default_location => false,
    www_root             => '/var/www',
  }
  file { '/var/www/':
    ensure => directory,
    owner  => 'root',
    mode   => '0755',
  }
  file { '/var/www/index.html':
    ensure => file,
    owner  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/profile/graphite/grafana-8080-index.html',
  }

}
