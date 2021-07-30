class profile::delivery::signer::monitor inherits ::profile::monitoring::icinga2::common {

  icinga2::object::service { 'signer-gpg-agent':
    check_command => 'procs',
    vars          => {
      'procs_critical'      => '1:1',
      'procs_warning'       => '1:1',
      'procs_command'       => 'gpg-agent',
      'procs_user'          => 'jenkins',
      'escalate'            => true,
      'notification_period' => $::profile::monitoring::icinga2::common::notification_period,
    },
    zone          => $::profile::monitoring::icinga2::common::zone,
  }
}
