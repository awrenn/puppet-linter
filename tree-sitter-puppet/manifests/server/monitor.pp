class profile::server::monitor (
  Boolean $check_swap = true,
  String[1] $swap_warn_free = '10%',
  String[1] $swap_crit_free = '5%',
  Array[String[1]] $disk_partitions = ['/'],
  String $disk_ignore_path = '/var/lib/docker/aufs',
  String $disk_wfree = '6%',
  String $disk_cfree = '3%',
  String $disk_inode_wfree = '20%',
  String $disk_inode_cfree = '10%',
  String[1] $pe_console_server = 'peconsole.ops.puppetlabs.net',
  Boolean $check_disk_ro = true,
  Integer[1] $last_run_time_warning = 3*60,
  Integer[1] $last_run_time_critical = 6*60,
  Array[Profile::Server::Monitor::CoreCheck] $checks_to_escalate = ['disk', 'swap'],
  Array[Profile::Server::Monitor::CoreCheck] $checks_to_chat = ['meminfo', 'disk', 'swap', 'zombie-procs', 'ro-disks', 'puppet-agent'],
  Array[Profile::Server::Monitor::CoreCheck] $checks_to_ticket = ['disk', 'puppet-agent'],
  Optional[Integer] $check_swap_max_check_attempts = undef,
) inherits ::profile::monitoring::icinga2::common {

  $processorcount2 = $facts['processors']['count']*2
  $processorcount3 = $facts['processors']['count']*3

  case $::profile::monitoring::icinga2::common::agent_provider {
    'icinga2-client': {
      include profile::monitoring::icinga2::server

      if $::kernel == 'Linux' {
        icinga2::object::service { 'meminfo':
          check_command  => 'meminfo',
          check_interval => '60s',
          vars           => {
            meminfo_keys           => 'MemFree',
            escalate               => ('meminfo' in $checks_to_escalate),
            notify_chat            => ('meminfo' in $checks_to_chat),
            create_incident_ticket => ('meminfo' in $checks_to_ticket),
            notification_period    => $::profile::monitoring::icinga2::common::notification_period,
          },
        }
      }

      icinga2::object::service { 'disk':
        check_command => 'disk',
        action_url    => 'https://confluence.puppetlabs.com/display/SRE/Icinga2+checks+that+may+escalate#Icinga2checksthatmayescalate-Checkdisk',
        vars          => {
          'disk_partitions'      => $disk_partitions,
          disk_local             => true,
          disk_wfree             => $disk_wfree,
          disk_cfree             => $disk_cfree,
          disk_inode_wfree       => $disk_inode_wfree,
          disk_inode_cfree       => $disk_inode_cfree,
          disk_ignore_ereg_path  => $disk_ignore_path,
          escalate               => ('disk' in $checks_to_escalate),
          notify_chat            => ('disk' in $checks_to_chat),
          create_incident_ticket => ('disk' in $checks_to_ticket),
          notification_period    => $::profile::monitoring::icinga2::common::notification_period,
        },
      }

      if $check_swap {
        icinga2::object::service { 'swap':
          check_command      => 'swap',
          max_check_attempts => $check_swap_max_check_attempts,
          vars               => {
            swap_wfree             => $swap_warn_free,
            swap_cfree             => $swap_crit_free,
            escalate               => ('swap' in $checks_to_escalate),
            notify_chat            => ('swap' in $checks_to_chat),
            create_incident_ticket => ('swap' in $checks_to_ticket),
            notification_period    => $::profile::monitoring::icinga2::common::notification_period,
          },
        }
      }

      icinga2::object::service { 'load':
        check_command => 'load',
        vars          => {
          load_wload1            => $processorcount2,
          load_wload5            => $processorcount2,
          load_wload15           => $processorcount2,
          load_cload1            => $processorcount3,
          load_cload5            => $processorcount3,
          load_cload15           => $processorcount3,
          escalate               => ('load' in $checks_to_escalate),
          notify_chat            => ('load' in $checks_to_chat),
          create_incident_ticket => ('load' in $checks_to_ticket),
          notification_period    => $::profile::monitoring::icinga2::common::notification_period,
        },
      }

      icinga2::object::service { 'ssh':
        check_command => 'ssh',
      }

      icinga2::object::service { 'zombie-procs':
        check_command => 'procs',
        vars          => {
          procs_warning          => '8',
          procs_critical         => '16',
          procs_state            => ['Z'],
          escalate               => ('zombie-procs' in $checks_to_escalate),
          notify_chat            => ('zombie-procs' in $checks_to_chat),
          create_incident_ticket => ('zombie-procs' in $checks_to_ticket),
          notification_period    => $::profile::monitoring::icinga2::common::notification_period,
        },
      }

      if $check_disk_ro {
        icinga2::object::service { 'ro-disks':
          check_command => 'ro-disks',
          vars          => {
            escalate               => ('ro-disks' in $checks_to_escalate),
            notify_chat            => ('ro-disks' in $checks_to_chat),
            create_incident_ticket => ('ro-disks' in $checks_to_ticket),
            notification_period    => $::profile::monitoring::icinga2::common::notification_period,
          },
        }
      }

      $puppet_base_check_doc_link = 'https://confluence.puppetlabs.com/display/SRE/Service+Checks+for+the+SRE+Internal+Puppet+Infrastructure#ServiceChecksfortheSysOpsInternalPuppetInfrastructure'

      icinga2::object::service {
        default:
          notes_url => "https://${pe_console_server}/#/inspect/node/${trusted['certname']}/reports",
        ;
        'puppet-agent-agent_disabled':
          check_command      => 'puppet-agent-agent_disabled',
          check_interval     => '15m',
          retry_interval     => '15m',
          max_check_attempts => 24*60/15,
          action_url         => "${puppet_base_check_doc_link}-Agentdisabledcheck",
          vars               => {
            escalate               => ('puppet-agent' in $checks_to_escalate),
            notify_chat            => ('puppet-agent' in $checks_to_chat),
            create_incident_ticket => ('puppet-agent' in $checks_to_ticket),
            notification_period    => $::profile::monitoring::icinga2::common::notification_period,
          }
        ;
        'puppet-agent-last_run_time':
          check_command => 'puppet-agent-last_run_time',
          action_url    => "${puppet_base_check_doc_link}-PuppetAgentlastruntimecheck",
          vars          => {
            parent_service         => 'puppet-agent-agent_disabled',
            escalate               => ('puppet-agent' in $checks_to_escalate),
            notify_chat            => ('puppet-agent' in $checks_to_chat),
            create_incident_ticket => ('puppet-agent' in $checks_to_ticket),
            notification_period    => $::profile::monitoring::icinga2::common::notification_period,
            warn_minutes           => $last_run_time_warning,
            crit_minutes           => $last_run_time_critical,
          },
        ;
        'puppet-agent-last_run_status':
          check_command      => 'puppet-agent-last_run_status',
          max_check_attempts => 6,
          check_interval     => '30m',
          retry_interval     => '30m',
          action_url         => "${puppet_base_check_doc_link}-PuppetAgentlastrunstatuscheck",
          vars               => {
            parent_service         => 'puppet-agent-last_run_time',
            escalate               => ('puppet-agent' in $checks_to_escalate),
            notify_chat            => ('puppet-agent' in $checks_to_chat),
            create_incident_ticket => ('puppet-agent' in $checks_to_ticket),
            notification_period    => $::profile::monitoring::icinga2::common::notification_period,
          },
        ;
        'puppet-agent-environment':
          check_command      => 'puppet-agent-environment',
          check_interval     => '1h',
          retry_interval     => '1h',
          max_check_attempts => 24*3,
          action_url         => "${puppet_base_check_doc_link}-PuppetAgentenvironmentcheck",
          vars               => {
            parent_service         => 'puppet-agent-last_run_status',
            escalate               => ('puppet-agent' in $checks_to_escalate),
            notify_chat            => ('puppet-agent' in $checks_to_chat),
            create_incident_ticket => ('puppet-agent' in $checks_to_ticket),
            notification_period    => $::profile::monitoring::icinga2::common::notification_period,
          },
        ;
      }
    }
    'icinga2-ssh': {
      include profile::monitoring::icinga2::ssh
      $plugin_directory = $::profile::monitoring::icinga2::common::plugin_dir

      @@icinga2::object::service {
        default:
          template_to_import => 'by_ssh-service',
          check_command      => 'by_ssh',
        ;
        'disk':
          vars                    => {
            by_ssh_command         => "${plugin_directory}/check_disk -w 6% -c 3% -W 6% -K 3% -l /",
            escalate               => ('disk' in $checks_to_escalate),
            notify_chat            => ('disk' in $checks_to_chat),
            create_incident_ticket => ('disk' in $checks_to_ticket),
            notification_period    => $::profile::monitoring::icinga2::common::notification_period,
          },
        ;
        'load':
          vars          => {
            by_ssh_command         => "${plugin_directory}/check_load -w ${processorcount2} -c ${processorcount3}",
            escalate               => ('load' in $checks_to_escalate),
            notify_chat            => ('load' in $checks_to_chat),
            create_incident_ticket => ('load' in $checks_to_ticket),
            notification_period    => $::profile::monitoring::icinga2::common::notification_period,
          },
        ;
        'zombie-procs':
          vars          => {
            by_ssh_command         => "${plugin_directory}/check_procs -s 8 -c 16 -s Z",
            escalate               => ('zombie-procs' in $checks_to_escalate),
            notify_chat            => ('zombie-procs' in $checks_to_chat),
            create_incident_ticket => ('zombie-procs' in $checks_to_ticket),
            notification_period    => $::profile::monitoring::icinga2::common::notification_period,
          },
        ;
      }

      @@icinga2::object::service { 'ssh':
        check_command => 'ssh',
        zone          => $::profile::monitoring::icinga2::common::parent_zone,
      }
      $puppet_agent_base_command = [
        'sudo',
        "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_puppet_agent.py",
        '--check-type',
      ]

      @@icinga2::object::service {
        default:
          check_command      => 'by_ssh',
          template_to_import => 'by_ssh-service',
          notes_url          => "https://${pe_console_server}/#/inspect/node/${trusted['certname']}/reports",
        ;
        'puppet-agent-agent_disabled':
          check_interval     => '15m',
          retry_interval     => '15m',
          max_check_attempts => 96,
          vars               => {
            by_ssh_command         => join($puppet_agent_base_command << 'agent_disabled', ' '),
            escalate               => ('puppet-agent' in $checks_to_escalate),
            notify_chat            => ('puppet-agent' in $checks_to_chat),
            create_incident_ticket => ('puppet-agent' in $checks_to_ticket),
            notification_period    => $::profile::monitoring::icinga2::common::notification_period,
          },
        ;
        'puppet-agent-last_run_time':
          vars           => {
            parent_service         => 'puppet-agent-agent_disabled',
            by_ssh_command         => join($puppet_agent_base_command << 'last_run_time', ' '),
            escalate               => ('puppet-agent' in $checks_to_escalate),
            notify_chat            => ('puppet-agent' in $checks_to_chat),
            create_incident_ticket => ('puppet-agent' in $checks_to_ticket),
            notification_period    => $::profile::monitoring::icinga2::common::notification_period,
          },
        ;
        'puppet-agent-last_run_status':
          vars           => {
            parent_service         => 'puppet-agent-last_run_time',
            by_ssh_command         => join($puppet_agent_base_command << 'last_run_status', ' '),
            escalate               => ('puppet-agent' in $checks_to_escalate),
            notify_chat            => ('puppet-agent' in $checks_to_chat),
            create_incident_ticket => ('puppet-agent' in $checks_to_ticket),
            notification_period    => $::profile::monitoring::icinga2::common::notification_period,
          },
        ;
        'puppet-agent-environment':
          check_interval     => '1h',
          retry_interval     => '1h',
          max_check_attempts => 24,
          vars               => {
            parent_service         => 'puppet-agent-environment',
            by_ssh_command         => join($puppet_agent_base_command << 'environment', ' '),
            escalate               => ('puppet-agent' in $checks_to_escalate),
            notify_chat            => ('puppet-agent' in $checks_to_chat),
            create_incident_ticket => ('puppet-agent' in $checks_to_ticket),
            notification_period    => $::profile::monitoring::icinga2::common::notification_period,
          },
        ;
      }
    }
  }
}
