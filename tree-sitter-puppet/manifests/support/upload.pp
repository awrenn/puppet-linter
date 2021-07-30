# A profile for support uploads service
class profile::support::upload (
  $cname      = 'support-upload.puppetlabs.com',
  $approot    = '/opt/supportupload',
  $passwdfile = '/etc/nginx/htpasswd'
){

  include profile::nginx
  include profile::server::params
  include profile::ssl::support_upload

  if $::profile::server::params::monitoring {
    include profile::support::upload::monitor
  }

  class { 'support_upload':
    rails_root => $approot,
    vhost_name => $cname,
  }

  Group <| name == 'allstaff' |>
  ['support', 'developers', 'prosvc'].each |$g| {
    Account::User <| groups == $g |>
  }

  ssh::allowgroup { 'support': }
  ssh::allowgroup { 'developers': }
  ssh::allowgroup { 'prosvc': }

  sudo::allowgroup { 'support': }
  sudo::allowgroup { 'developers': }
  sudo::allowgroup { 'prosvc': }
  $socket = "unix:${::support_upload::unicorn_socket}"
  nginx::resource::upstream { "unicorn_${cname}":
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

  file { $passwdfile:
    ensure => file,
    owner  => 'root',
    group  => 'www-data',
    mode   => '0660',
  }

  file_line { 'OpsMonitor':
    path => $passwdfile,
    line => 'opsmonitor:$apr1$x6a3o5pG$1eMcPn4Udd9nRoqKlUeRV0',
  }

  nginx::resource::server { $cname:
    listen_options       => 'default_server',
    ssl                  => true,
    ssl_cert             => $::profile::ssl::support_upload::certfile,
    ssl_key              => $::profile::ssl::support_upload::keyfile,
    client_max_body_size => '100G',
    server_cfg_prepend   => {
      'add_header X-Forwarded-By' => '$hostname',
    },
    www_root             => "${approot}/public",
    try_files            => [
      '$uri/index.html',
      '$uri.html',
      '$uri',
      '@app',
    ],
    auth_basic_user_file => $passwdfile,
    auth_basic           => 'Please authenticate.',
    server_cfg_append    => { 'client_body_temp_path' => '/var/tmp' },
  }

  nginx::resource::location { "default ssl_${cname}":
    server   => $cname,
    ssl      => true,
    ssl_only => true,
    location => '@app',
    proxy    => "http://unicorn_${cname}",
  }

}
