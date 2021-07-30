class profile::vmpooler::instance::cinext (
  String $vsphere_password,
  String $redis_password,
  String $config_folder,
  String $redis_server = 'vmpooler-redis-prod-2.delivery.puppetlabs.net',
  String $instance_name = 'vmpooler-cinext',
  String $provider = 'vsphere-ci65',
) {

  $config_file = "${config_folder}/${instance_name}.yaml"

  profile::vmpooler::config { $instance_name:
    ssh_key                    => '/var/lib/vmpooler/id_rsa-acceptance',
    vm_lifetime                => 2,
    vm_lifetime_auth           => 12,
    max_lifetime_upper_limit   => 336,
    task_limit                 => 20,
    redis_server               => $redis_server,
    redis_ttl                  => 168,
    timeout                    => 15,
    retry_factor               => 20,
    migration_limit            => 10,
    config_file                => $config_file,
    manage_host_selection      => false,
    experimental_features      => true,
    prometheus_prefix          => $instance_name,
    site_name                  => "<b>${instance_name}</b>.delivery.puppetlabs.net",
    redis_password             => $redis_password,
    purge_unconfigured_folders => true,
    backend_weight             => {
      'acceptance1' => 0,
      'acceptance2' => 100,
      'acceptance4' => 180,
    },
  }

  profile::vmpooler::provider { "${instance_name}_${provider}":
    username                => 'eso-vmpooler@vsphere.local',
    password                => $vsphere_password,
    config_file             => $config_file,
    server                  => 'vcenter-ci1.ops.puppetlabs.net',
    insecure                => true,
    provider_name           => $provider,
    connection_pool_size    => 65,
    connection_pool_timeout => 100,
  }

  class { 'profile::vmpooler::pools::cinext':
    folder_name  => 'infrastructure/ci-next/vmpooler-cinext',
    config_file  => $config_file,
    provider     => $provider,
    datacenter   => 'opdx',
    clone_target => 'acceptance1',
    datastore    => 'instance3_1',
  }

  class { 'profile::vmpooler::pools::cinext_pix':
    folder_name                   => 'infrastructure/ci-next/vmpooler-cinext',
    config_file                   => $config_file,
    provider                      => $provider,
    datacenter                    => 'pix',
    clone_target                  => 'acceptance2',
    datastore                     => 'vmpooler_acceptance2',
    snapshot_mainmem_ioblockpages => '2048',
    snapshot_mainmem_iowait       => '5',
  }

  class { 'profile::vmpooler::pools::cinext_pix_acceptance4':
    folder_name                   => 'infrastructure/ci-next/vmpooler-cinext/acceptance4',
    config_file                   => $config_file,
    provider                      => $provider,
    datacenter                    => 'pix',
    clone_target                  => 'acceptance4',
    datastore                     => 'vmpooler_acceptance4',
    snapshot_mainmem_ioblockpages => '2048',
    snapshot_mainmem_iowait       => '5',
  }

  @@icinga2::object::service { 'vmpooler-cinext':
    check_command      => 'vmpooler',
    check_interval     => '1m',
    retry_interval     => '1m',
    max_check_attempts => 120,
    action_url         => 'https://confluence.puppetlabs.com/display/SRE/Icinga2+checks+that+may+escalate#Icinga2checksthatmayescalate-Checkvmpoolerpools',
    tag                => ['singleton'],
    vars               => {
      url                    => "${instance_name}.delivery.puppetlabs.net",
      warning                => '70',
      critical               => '50',
      escalate               => false,
      create_incident_ticket => true,
      owner                  => 'dio',
    },
  }
}
