##
class profile::redis::monitor (
  Boolean $ticket_alerts = true,
  Boolean $escalate_alerts = false,
) inherits profile::monitoring::icinga2::common {

  icinga2::object::service { 'check-service-redis':
    check_command      => 'check-service-status',
    check_interval     => '1m',
    retry_interval     => '1m',
    max_check_attempts => 2,
    event_command      => 'restart_service',
    action_url         => 'https://confluence.puppetlabs.com/display/SRE/QE+On+Call#QEOnCall-Checkserviceredis',
    vars               => {
      service                => $redis::params::service_name,
      restart_service_name   => $redis::params::service_name,
      init_system            => 'systemd',
      create_incident_ticket => $ticket_alerts,
      escalate               => $escalate_alerts,
    },
  }
}
