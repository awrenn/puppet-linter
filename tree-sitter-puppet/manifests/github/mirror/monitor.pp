class profile::github::mirror::monitor inherits ::profile::monitoring::icinga2::common {

  @@icinga2::object::service { 'http-github.delivery.puppetlabs.net':
    check_command => 'http',
    vars          => {
      http_vhost   => 'github.delivery.puppetlabs.net',
      http_ssl     => false,
      http_timeout => '30',
    },
    tag           => ['singleton'],
  }
}
