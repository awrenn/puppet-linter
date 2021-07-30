class profile::graphite::monitor::web inherits ::profile::monitoring::icinga2::common {

  # Gunicorn should be running
  icinga2::object::service { 'gunicorn':
    check_command => 'procs',
    vars          => {
      'procs_critical' => '1:',
      'procs_argument' => '/usr/bin/gunicorn',
      'procs_warning'  => '1:',
    },
  }

}
