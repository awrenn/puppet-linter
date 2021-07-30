# this class is for forgenext icinga2 monitoring checks that should be
# classified to each app server
class profile::forgenext::loadbalancer::monitor inherits profile::monitoring::icinga2::common {

  $forge_urls = [
    'forge.puppetlabs.com',
    'forgeapi.puppetlabs.com',
    'forge.puppet.com',
    'forgeapi.puppet.com',
    "forgenext-web-${facts['classification']['stage']}.ops.puppetlabs.net",
    "forgenext-api-${facts['classification']['stage']}.ops.puppetlabs.net",
  ]

  $forge_urls.each |String[1] $website| {
    @@icinga2::object::service { "ssl-cert-${facts['classification']['stage']}-${website}":
      check_command => 'http',
      vars          => {
        http_address     => $facts['networking']['ip'],
        http_vhost       => $website,
        http_uri         => '/ping',
        http_ssl         => true,
        http_sni         => true,
        http_certificate => '30,14',
        escalate         => true,
      },
    }
  }

  icinga2::object::service { 'haproxy':
    check_command => 'check-service-status',
    vars          => {
      service  => 'haproxy',
      escalate => true,
    },
  }

  if lookup('profile::forgenext::loadbalancer:keepalived_eip', undef, undef, false) {
    # TODO: add aggregate check for keepalived
    icinga2::object::service { 'keepalived':
      check_command => 'check-service-status',
      vars          => {
        service  => 'keepalived',
        escalate => true,
      },
    }
  }

  ['forge','forgeapi'].each |String[1] $backend| {
    icinga2::object::service { "${backend}_backend_count":
      check_command => 'haproxy_backend_count',
      vars          => {
        name           => "${backend} backend count",
        warn_threshold => 1,
        crit_threshold => 2,
        backend        => $backend,
        escalate       => true,
      },
    }
  }
}
