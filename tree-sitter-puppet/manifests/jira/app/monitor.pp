class profile::jira::app::monitor (
  String[1] $password,
  String[1] $username,
  Boolean   $pingdom_pause = false,
) inherits profile::monitoring::icinga2::common {
  include jira

  @@icinga2::object::service {
    'check-jira-auth':
      check_command => 'check-jira-auth',
      vars          => {
        url      => "https://${jira::app_host}",
        username => $username,
        password => $password,
        escalate => true,
      }
      ;
    "http-${jira::app_host}":
      check_command => 'http',
      vars          => {
        http_vhost   => $jira::app_host,
        http_address => $jira::app_host,
        http_uri     => "https://${jira::app_host}/status",
        http_ssl     => true,
        http_timeout => '60',
        escalate     => true,
      }
      ;
    "ssl-cert-valid-${jira::app_host}":
      check_command => 'check_ssl_cert',
      vars          => {
        host           => $jira::app_host,
        rootcert       => '/etc/ssl/certs',
        escalate       => true,
        warning_days   => '30',
        critical_days  => '7',
        parent_service => "http-${jira::app_host}",
      },
  }

  # Disable pingdom for Java timezone update every Saturday at 9:55 pm PT
  # Search for OPS-6241 to find related code.
  if $pingdom_pause {
    pingdom::pause { $jira::app_host:
      weekday       => 'Saturday',
      hour          => 21,
      minute        => 55,
      pause_minutes => 15,
    }
  }
}
