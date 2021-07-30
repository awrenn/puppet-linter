class profile::zookeeper::monitor (
  Boolean $escalate_alerts = false,
  Boolean $ticket_alerts = true,
) inherits profile::monitoring::icinga2::common {

  @@icinga2::object::service { 'zookeeper':
    check_command => 'zookeeper_status',
    vars          => {
      'zk_host'              => $facts['networking']['fqdn'],
      escalate               => $escalate_alerts,
      create_incident_ticket => $ticket_alerts,
    },
  }
}
