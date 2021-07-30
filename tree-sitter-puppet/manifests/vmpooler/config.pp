# A type for creating vmpooler configuration files
define profile::vmpooler::config (
  String $prometheus_prefix = $title,
  String $site_name = "<b>${title}</b>.delivery.puppetlabs.net",
  String $clone_target = 'acceptance1',
  String $config_file = "/etc/vmpooler/${title}.yaml",
  Integer $task_limit = 10,
  Integer $vm_lifetime = 2,
  Integer $vm_lifetime_auth = 12,
  Integer $max_lifetime_upper_limit = 168,
  String $redis_server = 'localhost',
  Integer $redis_ttl = 168,
  Boolean $create_folders = true,
  Boolean $manage_host_selection = true,
  Boolean $create_template_delta_disks = true,
  Boolean $experimental_features = true,
  String $ldap_server = 'ldap.puppetlabs.com',
  Integer $ldap_port = 389,
  Array[String] $ldap_base = ['ou=users,dc=puppetlabs,dc=com', 'ou=service,ou=users,dc=puppetlabs,dc=com'],
  Array[String] $ldap_user_object = ['uid', 'cn'],
  Optional[Integer] $max_tries = 3,
  Optional[Integer] $retry_factor = 10,
  Optional[Integer] $migration_limit = undef,
  Optional[Integer] $timeout = undef,
  Optional[Integer] $connection_pool_size = undef,
  Optional[Integer] $connection_pool_timeout = undef,
  Optional[String] $ssh_key  = undef,
  Optional[Array[String[1]]] $allowed_tags = undef,
  Optional[Integer] $host_selection_max_age = undef,
  Optional[Integer] $utilization_limit = undef,
  Optional[Integer] $redis_port = undef,
  Optional[String[1]] $redis_password = undef,
  Optional[Boolean] $purge_unconfigured_folders = undef,
  Optional[Hash[String, Integer]] $backend_weight = undef,
) {

  concat { $config_file:
    owner => 'root',
    group => 'root',
    mode  => '0640',
  }

  concat::fragment {
    default:
      target => $config_file
      ;
    "${title}_vmpooler_config_base":
      content => template('profile/vmpooler/config_base.yaml.erb'),
      order   => '01'
      ;
    "${title}_pools_base":
      content => "\n:pools:\n",
      order   => '04'
      ;
  }
}
