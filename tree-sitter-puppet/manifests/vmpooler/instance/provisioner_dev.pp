# A class for deploying a configuration for a vmpooler instance
class profile::vmpooler::instance::provisioner_dev (
  String $vsphere_password,
  String $config_folder = '/etc/vmpooler',
  String $instance_name = 'vmpooler-provisioner-dev-2',
  String $redis_server = 'vmpooler-redis-test-1.delivery.puppetlabs.net'
) {

  $config_file = "${config_folder}/${instance_name}.yaml"

  profile::vmpooler::config { $instance_name:
    ssh_key                    => '/var/lib/vmpooler/id_rsa-acceptance',
    vm_lifetime                => 1,
    vm_lifetime_auth           => 2,
    max_lifetime_upper_limit   => 24,
    redis_server               => $redis_server,
    redis_ttl                  => 1,
    config_file                => $config_file,
    manage_host_selection      => false,
    migration_limit            => 3,
    purge_unconfigured_folders => true,
    backend_weight             => {
      'acceptance1' => 5,
      'acceptance2' => 6,
    },
  }

  profile::vmpooler::provider { "${instance_name}_vsphere-ci65":
    server                  => 'vcenter-ci1.ops.puppetlabs.net',
    username                => 'eso-vmpooler@vsphere.local',
    password                => $vsphere_password,
    insecure                => true,
    provider_name           => 'vsphere-ci65',
    connection_pool_size    => 5,
    connection_pool_timeout => 60,
    config_file             => $config_file,
  }

  include profile::vmpooler::pools::vmpooler_provisioner_dev

}
