# Combined NGINX logging
#
# nginx::resource::server { $vhost_name:
#   . . .
#   format_log => 'logstash_json',
#   access_log => '/var/log/nginx/access.log',
#   error_log  => '/var/log/nginx/error.log',
# }
class profile::nginx::logging {
  include profile::logging::logstashforwarder

  logstashforwarder::file { 'nginx_access':
    paths  => [ '/var/log/nginx/access.log' ],
    fields => {
      'type' => 'nginx_access_json',
    },
  }

  logstashforwarder::file { 'nginx_error':
    paths  => [ '/var/log/nginx/error.log' ],
    fields => {
      'type' => 'nginx_error',
    },
  }
}
