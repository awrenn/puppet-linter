class profile::downloadserver::monitor inherits profile::monitoring::icinga2::common {

  $website = 'pm.puppetlabs.com'
  @@icinga2::object::service {
    default:
      tag => ['singleton']
      ;
    "http-${website}":
      check_command => 'http',
      action_url    => 'https://confluence.puppetlabs.com/display/SRE/Apt+and+Yum+Download+Service+Docs',
      vars          => {
        http_address => $website,
        http_vhost   => $website,
        http_timeout => '60',
        http_ssl     => true,
      }
      ;
    "ssl-cert-valid-${website}":
      check_command => 'check_ssl_cert',
      action_url    => 'https://confluence.puppetlabs.com/display/SRE/Apt+and+Yum+Download+Service+Docs',
      vars          => {
        host           => $website,
        rootcert       => '/etc/ssl/certs',
        warning_days   => '30',
        critical_days  => '7',
        parent_service => "http-${website}",
      },
  }
}
