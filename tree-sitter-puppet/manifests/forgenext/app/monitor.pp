# this class is for forgenext icinga2 monitoring checks that should be
# classified to each app server
class profile::forgenext::app::monitor inherits ::profile::monitoring::icinga2::common {
  $forge_urls = [
    'forge.puppetlabs.com',
    'forgeapi.puppetlabs.com',
    "forgenext-web-${facts['classification']['stage']}.ops.puppetlabs.net",
    "forgenext-api-${facts['classification']['stage']}.ops.puppetlabs.net",
  ]

  $forge_urls.each |String[1] $website| {
    @@icinga2::object::service { "http-${facts['classification']['group']}-${facts['classification']['stage']}-${website}":
      check_command => 'http',
      vars          => {
        http_address    => $facts['networking']['ip'],
        http_vhost      => $website,
        http_uri        => '/ping',
        http_onredirect => 'critical', # /ping should never redirect
        http_port       => '8080',
        http_timeout    => '60',
        http_ssl        => false,
        escalate        => true,
      },
      tag           => ['singleton'],
    }
  }

  icinga2::object::service { 'unicorn-status-forge-api':
    check_command => 'check-service-status',
    vars          => {
      service  => 'unicorn_forge-api',
      escalate => true,
    },
  }

  icinga2::object::service { 'unicorn-status-forge-web':
    check_command => 'check-service-status',
    vars          => {
      service  => 'unicorn_forge-web',
      escalate => true,
    },
  }

  icinga2::object::service { 'rds_postgresql_connection_check':
    check_command => 'postgres',
    vars          => {
      action   => 'connection',
      hosts    => $::profile::forgenext::api::db_host,
      db_name  => $::profile::forgenext::api::db_name,
      db_user  => $::profile::forgenext::api::db_user,
      db_pass  => $::profile::forgenext::api::db_password,
      escalate => true,
    },
  }

  # Alert if fewer than 8 of the forge app servers can reach the database
  @@icinga2::object::service { 'aggregate_rds_postgresql_connection_check':
    check_command => 'aggregated-check',
    vars          => {
      icinga_service_filter => '"role::forgenext::app" in host.groups && service.name == "rds_postgresql_connection_check"',
      check_name            => 'aggregate_rds_postgresql_connection_check',
      icinga_api_username   => 'icinga2',
      icinga_api_password   => hiera('icinga2_apiuser_pass'),
      check_state           => 'ok',
      warn_threshold        => '10',
      crit_threshold        => '8',
      threshold_order       => 'min',
      escalate              => true,
    },
    zone          => $profile::monitoring::icinga2::common::master_zone,
    tag           => ['singleton'],
  }

}
