class profile::graphite::nginx {

  include profile::nginx

  $static_config = {
    'access_log' => 'off',
  }
  $content_config = {
    'access_log' => 'off',
    'expires'    => '30d',
  }

  nginx::resource::server { '1-graphite':
    ensure                => present,
    listen_port           => 80,
    server_name           => ["${facts['networking']['fqdn']}", 'graphite.ops.puppetlabs.net'],
    client_max_body_size  => '64M',
    proxy                 => 'http://unix:/var/run/graphite.sock:/',
    proxy_read_timeout    => '60',
    proxy_connect_timeout => '10',
    proxy_set_header      => ['X-Real-IP $remote_addr', 'Host $http_host'],
    proxy_redirect        => 'off',
    location_cfg_prepend  => {
      'add_header Access-Control-Allow-Origin' => 'http://grafana.ops.puppetlabs.net',
    },
  }

  nginx::resource::location { '^~ /static/':
    ensure              => present,
    server              => '1-graphite',
    www_root            => '/usr/share/pyshared/django/contrib/admin',
    location_cfg_append => $static_config,
  }

  nginx::resource::location { '^~ /content/':
    ensure              => present,
    server              => '1-graphite',
    www_root            => '/opt/graphite/webapp',
    location_cfg_append => $content_config,
  }

  ::python::gunicorn { 'graphite':
    ensure    => present,
    dir       => '/opt/graphite/webapp/graphite',
    bind      => 'unix:/var/run/graphite.sock',
    timeout   => 60,
    appmodule => 'graphite_wsgi:application',
  }

}
