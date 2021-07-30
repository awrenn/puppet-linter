##
class profile::mesos::master::monitor (
  Optional[Variant[Array[String], String]] $framework = undef,
  Boolean $ticket_alerts = true,
  Boolean $escalate_alerts = false,
) inherits profile::monitoring::icinga2::common {

  if $framework != undef {
    $set_framework = true
  }

  @@icinga2::object::service { 'mesos-master':
    check_command => 'mesos',
    vars          => {
      host          => $facts['networking']['fqdn'],
      framework     => $framework,
      set_framework => $set_framework,
    },
  }

  icinga2::object::service {
    'check-service-mesos-master':
      check_command  => 'check-service-status',
      check_interval => '5m',
      action_url     => 'https://confluence.puppetlabs.com/display/SRE/Icinga2+checks+that+may+escalate#Icinga2checksthatmayescalate-Checkservicemesos-master',
      vars           => {
        'service'              => 'mesos-master',
        create_incident_ticket => $ticket_alerts,
        escalate               => $escalate_alerts,
      }
      ;
    'check-service-marathon':
      check_command      => 'check-service-status',
      check_interval     => '1m',
      event_command      => 'restart_service',
      max_check_attempts => 5,
      action_url         => 'https://confluence.puppetlabs.com/display/SRE/Icinga2+checks+that+may+escalate#Icinga2checksthatmayescalate-Checkservicemarathon',
      vars               => {
        service                => 'marathon',
        restart_service_name   => 'marathon',
        init_system            => 'systemd',
        create_incident_ticket => $ticket_alerts,
        escalate               => $escalate_alerts,
      },
  }
}
