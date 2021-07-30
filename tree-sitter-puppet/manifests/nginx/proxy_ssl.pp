# Terminate SSL for a non-SSL service.
#
# This makes sure all requests go to the canonical hostname, i.e.
# https://$hostname (everything else gets a 301 to the correct place).
#
# Parameters:
#   [*hostname*]             - Canonical hostname (e.g. tickets.puppetlabs.com).
#   [*client_max_body_size*] - Maximum size allowed for a request body.
#   [*proxy_port*]           - Port on localhost to proxy to.
#   [*proxy_set_header*]     - Extra headers to set on request to upstream.
#   [*proxy_cache*]          - Whether or not to enable caching in the proxy.
#   [*cache_size*]           - Size of cache to keep on disk.
#   [*cache_keys_count*]     - Number of keys to allocate shared memory for.
#                              There is generally no need to reduce this, as
#                              each 8000 keys will cause another 1MB of memory
#                              to be allocated. Thus, the default of 80,000
#                              keys will only allocate 10MB.
#   [*cache_inactive_time*]  - Interval after which inactive entries are
#                              removed. http://nginx.org/en/docs/syntax.html
#                              lists suffixes and their meaning.
#   [*client_set_header*]    - Extra headers to set on response to client.

class profile::nginx::proxy_ssl (
  String[1] $hostname                     = $facts['networking']['fqdn'],
  String[1] $client_max_body_size         = '10m',
  String[1] $proxy_http_version           = '1.1',
  String[1] $proxy_scheme                 = 'http',
  Integer $proxy_port                     = 8000,
  Array $proxy_set_header                 = [],
  Boolean $proxy_cache                    = false,
  String[1] $cache_size                   = '500m',
  Integer $cache_keys_count               = 80000,
  String $cache_inactive_time             = '1M',
  Hash $client_set_header                 = {},
  Optional[String[1]] $default_ssl_cert   = undef,
  Optional[String[1]] $default_ssl_key    = undef,
  Optional[String[1]] $canonical_ssl_cert = $default_ssl_cert,
  Optional[String[1]] $canonical_ssl_key  = $default_ssl_key,
) {
  include profile::server::params
  if $::profile::server::params::fw {
    include profile::fw::https
  }

  if $canonical_ssl_cert and $canonical_ssl_key {
    $canonical_info = {
      'cert' => $canonical_ssl_cert,
      'key'  => $canonical_ssl_key,
    }
  } else {
    $canonical_info = profile::ssl::host_info($hostname)
  }

  if $proxy_cache {
    $cache_keys_mb = ceiling($cache_keys_count/8000)
    $proxy_cache_zone = 'app'
    $cache_path = '/var/cache/nginx/proxy_cache'
    $add_header = {
      'X-Cache-Status' => '$upstream_cache_status',
    }

    class { '::profile::nginx':
      nginx_extras => {
        proxy_cache_path      => $cache_path,
        proxy_cache_levels    => '2:2',
        proxy_cache_keys_zone => "${proxy_cache_zone}:${cache_keys_mb}m",
        proxy_cache_max_size  => $cache_size,
        proxy_cache_inactive  => $cache_inactive_time,
        proxy_http_version    => $proxy_http_version,
        proxy_set_header      => $proxy_set_header,
      },
    }
    # before, NOT notify
    -> exec { 'purge NGINX cache':
      command     => "/usr/bin/find ${cache_path} -type f -delete",
      refreshonly => true,
      user        => 'root',
    }
  } else {
    $proxy_cache_zone = undef
    $add_header = {}
    class { '::profile::nginx':
      nginx_extras => {
        proxy_http_version => $proxy_http_version,
        proxy_set_header   => $proxy_set_header,
      },
    }
  }

  nginx::resource::upstream { 'app-upstream':
    cfg_prepend => {
      'keepalive' => '20',
    },
    members     => {
      "localhost:${proxy_port}" => {
        server       => 'localhost',
        port         => $proxy_port,
        fail_timeout => '10s',
      },
    },
  }

  # Redirect all requests to hosts not matching $hostname to https://$hostname
  profile::nginx::redirect { 'default':
    destination => "https://${hostname}",
    default     => true,
    ssl         => true,
    ssl_cert    => $default_ssl_cert,
    ssl_key     => $default_ssl_key,
  }

  # Proxy https://$hostname (and only that)
  nginx::resource::server { $hostname:
    listen_port          => 443, # only handle SSL
    http2                => 'on',
    ssl                  => true,
    ssl_cert             => $canonical_info['cert'],
    ssl_key              => $canonical_info['key'],
    proxy                => "${proxy_scheme}://app-upstream",
    proxy_set_header     => $proxy_set_header,
    proxy_cache          => $proxy_cache_zone,
    add_header           => $add_header + $client_set_header,
    client_max_body_size => $client_max_body_size,
    format_log           => 'logstash_json',
    server_cfg_append    => {
      error_page             => '502 503 504 /puppet-private-maintenance.html',
      proxy_intercept_errors => 'on',
    },
  }

  nginx::resource::location { "${hostname}__maintenance":
    server   => $hostname,
    ssl      => true,
    ssl_only => true,
    location => '= /puppet-private-maintenance.html',
    internal => true,
    www_root => '/var/nginx/maintenance',
  }

  include profile::server::params
  if $::profile::server::params::logging {
    include profile::logging::logstashforwarder

    ::logstashforwarder::file { "ssl-${hostname}_nginx_access":
      paths  => [ "/var/log/nginx/ssl-${hostname}.access.log" ],
      fields => {
        'type' => 'nginx_access_json',
      },
    }

    ::logstashforwarder::file { "ssl-${hostname}_nginx_error":
      paths  => [ "/var/log/nginx/ssl-${hostname}.error.log" ],
      fields => {
        'type' => 'nginx_error',
      },
    }
  }
}
