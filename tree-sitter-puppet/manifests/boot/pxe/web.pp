#
# profile::boot::pxe::web creates a webserver, mostly to distribute kickstart
# files for CentOS and ESXi.
#
class profile::boot::pxe::web(
  String[1] $canonical_fqdn = $facts['networking']['fqdn'],
  String[1] $www_root = '/webroot'
) {

  $web_dirs = [
    $www_root,
    "${www_root}/centos",
    "${www_root}/esxi",
  ]

  file { $web_dirs:
    ensure  => 'directory',
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => Package['nginx'],
    notify  => Service['nginx'],
  }

  # Serve https://$canonical_fqdn (and only that)
  $canonical_info = profile::ssl::host_info($canonical_fqdn)
  nginx::resource::server { $canonical_fqdn:
    listen_port => 443, # only handle SSL
    http2       => 'on',
    ssl         => true,
    ssl_cert    => $canonical_info['cert'],
    ssl_key     => $canonical_info['key'],
    www_root    => $www_root,
    format_log  => 'logstash_json',
    access_log  => '/var/log/nginx/access.log',
    error_log   => '/var/log/nginx/error.log',
  }

  class { 'profile::nginx::redirect::all':
    canonical_fqdn => $canonical_fqdn,
  }
}
