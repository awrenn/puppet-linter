class profile::graphite::monitor::carbon_c_relay inherits ::profile::monitoring::icinga2::common {

  icinga2::object::service { 'carbon-c-relay':
      check_command => 'procs',
      vars          => {
        'procs_critical' => '1:1',
        'procs_argument' => 'carbon-c-relay',
        'procs_warning'  => '1:',
      },
  }

}
