# Reverse proxy for Jenkins
class profile::jenkins::master::proxy (
  String[1] $site_alias = $facts['networking']['fqdn'],
  Optional[String[1]] $site_alias_cname = undef,
  Boolean $require_ssl = false,
) {
  class { '::apache::purge': }

  -> class { '::profile::nginx':
    # lingering_close always will cause nginx to unconditionally wait for and process additional client data.
    nginx_extras => {
      proxy_http_version => '1.1',
      lingering_close    => 'always',
    },
  }

  $ssl = profile::ssl::host_info($site_alias)
  if $require_ssl {
    # This creates a default for the domain
    profile::nginx::redirect { 'default':
      destination => "https://${site_alias}",
      default     => true,
      ssl         => true,
      ssl_cert    => $ssl['cert'],
      ssl_key     => $ssl['key'],
    }

    if $ssl['domain'] != $facts['networking']['domain'] {
      # Make sure we can redirect requests to our FQDN. We might as well match
      # everything in that domain at the same time.
      #
      # The name is different than the parameter because Puppet can't handle
      # tags (implicitly generated here) with asterisks in them.
      profile::nginx::redirect { "wildcard.${facts['networking']['domain']}":
        hostnames   => ["*.${facts['networking']['domain']}"],
        destination => "https://${site_alias}",
        ssl         => true,
      }
    }

    $listen_port = 443
  } else {
    # This actually means accept both HTTP and HTTPS
    $listen_port = 80
  }

  nginx::resource::upstream { 'app-upstream':
    cfg_prepend => {
      'keepalive' => '32',
    },
    members     => {
      'localhost:8080' => {
        server => 'localhost',
        port   => 8080,
      },
    },
  }

  [$site_alias,$site_alias_cname].delete_undef_values().each |$site| {
    nginx::resource::server { $site:
      listen_port          => $listen_port,
      ssl                  => true,
      ssl_cert             => $ssl['cert'],
      ssl_key              => $ssl['key'],
      proxy                => 'http://app-upstream',
      proxy_set_header     => [
        'Host               $host',
        'X-Real-IP          $remote_addr',
        'X-Forwarded-For    $proxy_add_x_forwarded_for',
        'Upgrade            $http_upgrade',
        'Connection         "upgrade"',
      ],
      client_max_body_size => '0', # Don't limit upload sizes
      format_log           => 'logstash_json',
      access_log           => "/var/log/nginx/${site}.access.log",
      error_log            => "/var/log/nginx/${site}.error.log",
      server_cfg_append    => {
        error_page             => '502 =302 http://maintenance.puppetlabs.com/',
        proxy_intercept_errors => 'on',
        # This is necessary to enable CSRF protection in Jenkins. Jenkins sends
        # a .crumb request header in Ajax. This may be fixed in Jenkins 2.0.
        # https://issues.jenkins-ci.org/browse/JENKINS-12875
        ignore_invalid_headers => 'off',
      },
    }
  }

  include profile::server::params
  if $::profile::server::params::logging {
    include profile::logging::logstashforwarder

    ::logstashforwarder::file { "${site_alias}_nginx_access":
      paths  => [ "/var/log/nginx/${site_alias}.access.log" ],
      fields => {
        'type' => 'nginx_access_json',
      },
    }

    ::logstashforwarder::file { "${site_alias}_nginx_error":
      paths  => [ "/var/log/nginx/${site_alias}.error.log" ],
      fields => {
        'type' => 'nginx_error',
      },
    }
  }
}
