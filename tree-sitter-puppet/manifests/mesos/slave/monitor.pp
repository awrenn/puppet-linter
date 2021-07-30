# Provide monitoring for mesos slaves / agents
#
class profile::mesos::slave::monitor (
  Boolean $monitor_docker_datafile = false,
  Boolean $monitor_docker_thinpool = false
) inherits ::profile::monitoring::icinga2::common {

  # QENG-4938
  if $monitor_docker_datafile {
    icinga2::object::service { 'docker-sparse-datafile-percentagefree':
      check_command  => 'check_docker_datafile',
      check_interval => '5m',
      action_url     => 'https://confluence.puppetlabs.com/display/SRE/CI+Lessons+Learned#CILessonsLearned-MesosAgentLVMLoopbackFileOutofSpace',
      vars           => {
        'datafile'             => '/var/lib/docker/devicemapper/devicemapper/data',
        'warn_free'            => 17,
        'critical_free'        => 12,
        create_incident_ticket => true,
      },
    }
  }

  # QENG-4991
  if $monitor_docker_thinpool {
    icinga2::object::service { 'docker-thinpool-percentagefree':
      check_command  => 'check_docker_thinpool',
      check_interval => '5m',
      action_url     => 'https://confluence.puppetlabs.com/display/ENG/CI.next+Monitoring#CI.nextMonitoring-Deletingandre-creatingaLVMthinpool',
      vars           => {
        'thinpool'             => 'docker-lvm/thinpool',
        'warn_free'            => 10,
        'critical_free'        => 5,
        create_incident_ticket => true,
      },
    }
  }

  icinga2::object::service { 'check-service-mesos-slave':
    check_command      => 'check-service-status',
    check_interval     => '5m',
    retry_interval     => '1m',
    max_check_attempts => 5,
    vars               => {
      'service'              => 'mesos-slave',
      create_incident_ticket => true,
    },
  }

  icinga2::object::service { 'check-service-docker':
    check_command      => 'check-service-status',
    check_interval     => '5m',
    retry_interval     => '1m',
    max_check_attempts => 5,
    vars               => {
      'service'              => 'docker',
      create_incident_ticket => true,
    },
  }
}
