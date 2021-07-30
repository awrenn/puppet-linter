# Class used to easily add web logging to a host
# To use, simply call this class and pass the access and error
# logs you want logstashforwarder to ship.
#
# Example:
#
#  class { profile::logging::weblogs:
#    access_files  => ['/var/log/apache2/access.log', '/var/log/nginx/mysite.log'],
#    error_files   => ['/var/log/nginx/error.log']
#  }


class profile::logging::weblogs (
  $access_files,
  $error_files
) {

  include profile::logging::logstashforwarder

  if $access_files != undef {
    logstashforwarder::file { 'web_access_logs':
      paths  => $access_files,
      fields => { 'type' => 'varnish' },
    }
  }

  if $error_files != undef {
    logstashforwarder::file { 'web_error_logs':
      paths  => $error_files,
      fields => { 'type' => 'nginx_error' },
    }
  }

}
