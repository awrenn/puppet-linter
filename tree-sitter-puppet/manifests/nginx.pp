class profile::nginx (
  $package_version = present,
  $nginx_extras = {},
) {
  include profile::server::params

  $package_name     = hiera('profile::nginx::package_name', 'nginx')
  $worker_processes = hiera('profile::nginx::worker_processes', 'auto')

  # Standard JSON log format used for most of our services
  $json_log_format = {
    time                        => '$time_iso8601',
    remote_addr                 => '$remote_addr',
    remote_user                 => '$remote_user',
    body_bytes_sent             => '$body_bytes_sent',
    http_request_time           => '$request_time',
    http_upstream_response_time => '$upstream_response_time',
    request_uri                 => '$request_uri',
    request_method              => '$request_method',
    scheme                      => '$scheme',
    http_status                 => '$status',
    http_host                   => '$http_host',
    server_name                 => '$server_name',
    server_port                 => '$server_port',
    http_referrer               => '$http_referer',
    http_x_unique_id            => '$http_X_Unique_ID',
    http_x_forwarded_port       => '$http_X_Forwarded_Port',
    http_x_forwarded_proto      => '$http_X_Forwarded_Proto',
    http_x_forwarded_for        => '$http_X_Forwarded_For',
    http_user_agent             => '$http_user_agent',
    facter_group                => $facts['classification']['group'],
    facter_stage                => $facts['classification']['stage'],
    facter_function             => $facts['classification']['function'],
  }.map |$key, $value| { "\"${key}\": \"${value}\"" }
    .join(',')
    .with |$string| { "'{ ${string} }'" }

  # Custom JSON log format for download servers to be backwards-compatible with the JSON format
  # that we had Apache generating; do not use this for anything new
  $downloadserver_json_log_format = {
    host          => '$http_host',
    time          => '$time_iso8601',
    client        => '$remote_addr',
    file          => '$request_uri',
    agent         => '$http_user_agent',
    request       => '$request_method',
    status        => '$status',
    response_size => '$body_bytes_sent',
    response_time => '$upstream_response_time',
  }.map |$key, $value| { "\"${key}\": \"${value}\"" }
    .join(',')
    .with |$string| { "'{ ${string} }'" }
  # ^ ad-hoc JSON conversion # ^ ad-hoc JSON conversion

  $nginx_default_params = {
    package_ensure   => $package_version,
    package_name     => $package_name,
    server_tokens    => 'off',
    worker_processes => $worker_processes,
    server_purge     => true,
    confd_purge      => true,
    http_cfg_append  => {
      # OPS-10017: block https://httpoxy.org vulnerability
      fastcgi_param => 'HTTP_PROXY ""',
    },
  }

  class { 'nginx':
    * => deep_merge($nginx_default_params, $nginx_extras),
  }

  $log_config = @("END")
    log_format logstash_json ${json_log_format};
    log_format downloadserver_logstash_json ${downloadserver_json_log_format};
    | END

  file { '/etc/nginx/conf.d/logformat.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $log_config,
    notify  => Service['nginx'],
  }

  file {
    # /var/nginx is created by the NGINX package.
    '/var/nginx/maintenance':
      ensure  => directory,
      mode    => '0755',
      owner   => 'root',
      group   => '0',
      recurse => true,
      purge   => true,
      force   => true,
    ;
    '/var/nginx/maintenance/puppet-private-maintenance.html':
      ensure => file,
      mode   => '0444',
      owner  => 'root',
      group  => '0',
      source => 'puppet:///modules/profile/nginx/maintenance/maintenance.html',
    ;
  }

  package { 'ngxtop':
    ensure   => 'present',
    provider => 'pip',
  }

  include ssl::params

  $dh_name = hiera('ssl::dh_param_name')
  $dh_bits = hiera('ssl::dh_param_bits')
  exec { 'make dhkey web':
    command => "/usr/bin/openssl dhparam -out ${dh_name} ${dh_bits}",
    cwd     => $ssl::params::key_dir,
    creates => "${ssl::params::key_dir}/${dh_name}",
    require => File[$ssl::params::key_dir],
    # This has to be the service in order to avoid dependency loops when
    # combined with apache::purge.
    notify  => Class['Nginx::Service'],
  }

  include puppetlabs::ssl
  if $profile::server::params::monitoring {
    include profile::nginx::monitor
  }

  if $profile::server::params::metrics {
    include profile::nginx::metrics
  }
}
