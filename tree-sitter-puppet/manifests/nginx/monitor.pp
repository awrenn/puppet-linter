class profile::nginx::monitor (
  Boolean $ticket_alerts = false,
  Boolean $escalate_alerts = false,
) inherits ::profile::monitoring::icinga2::common {
  icinga2::object::service { 'nginx':
    check_command => 'check-exit',
    vars          => {
      run_command            => '/usr/sbin/nginx -tq',
      escalate               => $escalate_alerts,
      create_incident_ticket => $ticket_alerts,
    },
  }
}
