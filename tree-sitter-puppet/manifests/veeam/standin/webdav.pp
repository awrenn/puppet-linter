# Class: profile::veeam::standin::webdav
#
# This class takes care of setting up Nginx to allow systems such as vCenter to
# put files on the Veeam Standin server via https.
#
class profile::veeam::standin::webdav (
  String[1] $canonical_fqdn = $facts['networking']['fqdn'],
  String[1] $www_root = '/backup-data/webroot',
  String[1] $webdav_tmp = '/backup-data/webdav_tmp',
) {
  include profile::nginx

  $vcenters = unwrap($profile::veeam::standin::sensitive_vcenters)
  $vcenter_dirs = $vcenters.each |Hash $vcenter| {
    file { "${www_root}/${vcenter[fqdn]}":
      ensure  => 'directory',
      mode    => '0700',
      owner   => 'nginx',
      group   => 'root',
      require => Package['nginx'],
      notify  => Service['nginx'],
    }
  }

  file {
    default:
      ensure => directory,
      mode   => '0770',
      owner  => 'root',
      group  => 'nginx',
    ;
    '/backup-data/.nginx_users':
      ensure => file,
      mode   => '0440',
      source => 'puppet:///modules/profile/veeam/standin/nginx_users',
    ;
    $webdav_tmp:
      owner => 'nginx',
    ;
    $www_root:
    ;
  }

  # Serve https://$canonical_fqdn (and only that)
  $canonical_info = profile::ssl::host_info($canonical_fqdn)
  nginx::resource::server { $canonical_fqdn:
    listen_port          => 443, # only handle SSL
    ssl                  => true,
    ssl_cert             => $canonical_info['cert'],
    ssl_key              => $canonical_info['key'],
    www_root             => $www_root,
    format_log           => 'logstash_json',
    access_log           => '/var/log/nginx/access.log',
    error_log            => '/var/log/nginx/error.log',

    # entires below here are related to webdav on this host
    auth_basic           => $canonical_fqdn,
    auth_basic_user_file => '/backup-data/.nginx_users',
    use_default_location => false,
    require              => [
      File[$webdav_tmp],
      File[$www_root],
    ],
  }

  nginx::resource::location { "${canonical_fqdn} /":
    server              => $canonical_fqdn,
    ssl                 => true,
    ssl_only            => true,
    location            => '/',
    location_custom_cfg => {
      'autoindex'             => 'on',
      'dav_methods'           => 'PUT DELETE MKCOL COPY MOVE',
      # 'dav_ext_methods'       => 'PROPFIND OPTIONS',
      'dav_access'            => 'user:rw',
      'client_max_body_size'  => 0,
      'create_full_put_path'  => 'on',
      'client_body_temp_path' => $webdav_tmp,
    },
    require             => [
      File[$webdav_tmp],
      File[$www_root],
    ],
  }

  class { 'profile::nginx::redirect::all':
    canonical_fqdn => $canonical_fqdn,
  }
}

