class profile::jenkins::monitor inherits ::profile::monitoring::icinga2::common {
  icinga2::object::service { 'check-jenkins':
    check_command => 'check-jenkins',
  }
}
