class profile::meat::monitor inherits profile::monitoring::icinga2::common {

  @@icinga2::object::service { 'http-meat.ops.puppetlabs.net':
    check_command => 'http',
    vars          => {
      http_vhost   => 'meat.ops.puppetlabs.net',
      http_address => 'meat.ops.puppetlabs.net',
      http_ssl     => false,
      http_timeout => '30',
    },
    tag           => ['singleton'],
  }
}
