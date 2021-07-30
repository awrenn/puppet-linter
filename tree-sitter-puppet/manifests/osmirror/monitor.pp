class profile::osmirror::monitor inherits ::profile::monitoring::icinga2::common {

  $urls = [
    'osmirror.delivery.puppetlabs.net',
    'buildsources.delivery.puppetlabs.net',
  ]

  # optional attributes: check_interval (service in hard state), defaults to 5mins.
  #                     retry_interval (service in soft state), defaults to 1min.
  #                     max_check_attempts (# times a host is re-checked before hard state), defaults to 3.
  # Objects re-checked a number of times (based on the max_check_attempts and retry_interval settings) before sending notifications.
  # This ensures that no unnecessary notifications are sent for transient failures.

  $urls.each |String $url| {
    @@icinga2::object::service { "http-${url}":
      check_command  => 'http',
      check_interval => '10m',
      retry_interval => '5m',
      vars           => {
        http_vhost   => $url,
        http_address => $url,
        http_timeout => '60',
        escalate     => true,
      },
    }
  }
}
