# Provide monitoring for docker storage devices
#
class profile::docker::monitor (
  Boolean $sparse_datafile = false,
  Boolean $lvm_thinpool = false,
  Integer $thinpool_warn_free = 15,
  Integer $thinpool_critical_free = 10
) inherits ::profile::monitoring::icinga2::common {

  # QENG-4938
  if $sparse_datafile {
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
  if $lvm_thinpool {
    icinga2::object::service { 'docker-thinpool-percentagefree':
      check_command      => 'check_docker_thinpool',
      check_interval     => '5m',
      event_command      => 'reset_docker_thinpool',
      retry_interval     => '4h',
      max_check_attempts => 5,
      action_url         => 'https://confluence.puppetlabs.com/display/ENG/CI.next+Monitoring#CI.nextMonitoring-Deletingandre-creatingaLVMthinpool',
      vars               => {
        'thinpool'             => 'docker-lvm/thinpool',
        'warn_free'            => $thinpool_warn_free,
        'critical_free'        => $thinpool_critical_free,
        'mesosagent'           => $fqdn,
        'mesosmaster'          => "leader.cinext-${facts['classification']['stage']}.mesos",
        create_incident_ticket => true,
      },
    }
  }
}
