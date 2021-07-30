class profile::distribution::monitor inherits ::profile::monitoring::icinga2::common {

  $urls = [
    'builds.delivery.puppetlabs.net',
    'release-web-prod-1.delivery.puppetlabs.net',
    'pl-build-tools.delivery.puppetlabs.net',
  ]

  $urls.each |String $url| {
    @@icinga2::object::service { "http-${url}":
      check_command => 'http',
      vars          => {
        http_vhost   => $url,
        http_address => $url,
        http_timeout => '60',
        escalate     => true,
      },
    }
  }
}
