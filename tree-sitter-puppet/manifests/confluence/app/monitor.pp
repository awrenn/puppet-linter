class profile::confluence::app::monitor (
  $pingdom_pause = false
) inherits profile::monitoring::icinga2::common {
  include confluence

  @@icinga2::object::service {
    "http-${confluence::app_host}":
      check_command => 'http',
      vars          => {
        http_vhost   => $confluence::app_host,
        http_address => $confluence::app_host,
        http_ssl     => true,
        http_uri     => "https://${confluence::app_host}/status",
        http_timeout => '30',
      }
      ;
    "ssl-cert-valid-${confluence::app_host}":
      check_command => 'check_ssl_cert',
      vars          => {
        host           => $confluence::app_host,
        rootcert       => '/etc/ssl/certs',
        escalate       => true,
        warning_days   => '30',
        critical_days  => '7',
        parent_service => "http-${confluence::app_host}",
      },
  }

  # Disable pingdom for Java timezone update every Saturday at 9:55 pm PT
  # Search for OPS-6241 to find related code.
  if $pingdom_pause {
    pingdom::pause { $confluence::app_host:
      weekday       => 'Saturday',
      hour          => 21,
      minute        => 55,
      pause_minutes => 15,
    }
  }
}
