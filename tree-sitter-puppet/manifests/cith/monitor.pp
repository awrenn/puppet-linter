# Provide checks for the CI Triage Helper service
# QENG-5501
class profile::cith::monitor {

  @@icinga2::object::service {
    'check_cith_api_cinext-cith-test':
      check_command  => 'cith_api',
      check_interval => '5m',
      vars           => {
        'cith_api_host' => 'cinext-cith-api-test.delivery.puppetlabs.net',
        'timeout'       => 5,
        'owner'         => 'dio',
      },
      tag            => ['singleton'],
      ;
  }

  @@icinga2::object::service {
    'check_cith_ui_cinext-cith-test':
      check_command  => 'cith_ui',
      check_interval => '5m',
      vars           => {
        'cith_api_host' => 'cinext-cith-ui-test.delivery.puppetlabs.net',
        'timeout'       => 5,
        'owner'         => 'dio',
      },
      tag            => ['singleton'],
      ;
  }

}
