class profile::support::upload::monitor inherits profile::monitoring::icinga2::common {

  @@icinga2::object::service { "http-${profile::support::upload::cname}":
    check_command => 'http',
    vars          => {
      http_vhost     => $profile::support::upload::cname,
      http_address   => $profile::support::upload::cname,
      http_ssl       => true,
      http_auth_pair => 'opsmonitor:9a8JIlPOUiVaUUCvA57T',
      http_uri       => '/',
    },
    tag           => ['singleton'],
  }
}
