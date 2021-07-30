# Class: profile::consul
#
# This class is expected to be wrapped by profile::consul::server,
# profile::consul::agent, or another wrapper class.
# Overrides are all set via hiera.
class profile::consul (
  String[1]            $version,
  String[1]            $datacenter,
  String[0]            $ca_file = '',
  String[0]            $cert_file = '',
  String[0]            $key_file = '',
  Sensitive[String[0]] $sensitive_acl_master_token = '',
  Sensitive[String[0]] $sensitive_agent_token = '',
  Array[String[1], 0]  $agents = profile::consul::ips('Profile::Consul::Agent'),
  String[1]            $consul_domain = 'consul',
  Sensitive[String[0]] $sensitive_encryption_key = '',
  Integer              $expected_cluster_size = 3,
  Array[String[1],0]   $extra_groups = [],
  Boolean              $server = false,
  String[1]            $consul_stage = 'prod',
) {
  include profile::server::params
  include profile::consul::pki

  if $facts['kernel'] == 'Linux' {
    include profile::ssl::ops
  }

  $_consul_conf_dir = $facts['kernel'] ? {
    'Linux'   => '/etc/consul',
    'windows' => 'C:/ProgramData/consul/config',
  }

  $_consul_data_dir = $facts['kernel'] ? {
    'Linux'   => '/opt/consul',
    'windows' => 'C:/ProgramData/consul',
  }

  $_consul_owner = $facts['kernel'] ? {
    'Linux'   => 'consul',
    'windows' => 'NT AUTHORITY\\NETWORK SERVICE',
  }

  $_consul_group = $facts['kernel'] ? {
    'Linux'   => 'consul',
    'windows' => 'Administrators',
  }

  if $ca_file == '' {
    $_real_ca_file = "${_consul_conf_dir}/pki/ca.crt"
  } else {
    $_real_ca_file = $ca_file
  }

  if $cert_file == '' {
    $_real_cert_file = "${_consul_conf_dir}/pki/${trusted['certname']}.crt"
  } else {
    $_real_cert_file = $cert_file
  }

  if $key_file == '' {
    $_real_key_file = "${_consul_conf_dir}/pki/${trusted['certname']}.pem"
  } else {
    $_real_key_file = $key_file
  }

  if $facts['os']['family'] == 'RedHat' {
    include selinux
  }

  ensure_packages(['jq'], {'ensure' => 'latest'})

  $_consul_enable_syslog = $facts['kernel'] ? {
    'Linux'   => true,
    'windows' => false,
  }

  $servers = profile::consul::ips('Profile::Consul::Server', $consul_stage).sort

  $base_config_hash_contents = {
    'primary_datacenter' => 'ops',
    'acl_default_policy' => 'deny',
    'acl_down_policy'    => 'extend-cache',
    'acl_master_token'   => unwrap($sensitive_acl_master_token),
    'acl_token'          => unwrap($sensitive_agent_token),
    'addresses'          => {
      'http'  => '127.0.0.1',
      'https' => $facts['networking']['ip'],
    },
    'bind_addr'          => $facts['networking']['ip'],
    'ca_file'            => $_real_ca_file,
    'cert_file'          => $_real_cert_file,
    'data_dir'           => $_consul_data_dir,
    'datacenter'         => $datacenter,
    'domain'             => $consul_domain,
    'enable_syslog'      => $_consul_enable_syslog,
    'encrypt'            => unwrap($sensitive_encryption_key),
    'key_file'           => $_real_key_file,
    'log_level'          => 'INFO',
    'node_name'          => $facts['networking']['fqdn'],
    'ports'              => {
      'http'  => '8500',
      'https' => '8500',
    },
    'retry_join'         => $servers,
    'verify_incoming'    => false,
    'verify_outgoing'    => true,
  }

# Adjust the hash depending on whether or not we're configuring a server.
  if $server {
    $config_hash_contents = $base_config_hash_contents + {
      'bootstrap_expect' => $expected_cluster_size,
      'client_addr'      => '0.0.0.0',
      'server'           => true,
      'serf_wan'         => $facts['networking']['ip'],
      'ui'               => true,
      'verify_outgoing'  => false,
    }
  } else {
    $config_hash_contents = $base_config_hash_contents + {
      'client_addr'     => '127.0.0.1',
      'server'          => false,
    }
  }

  case $facts['kernel'] {
    'Linux': {
      file { '/var/run/consul/':
        ensure => directory,
        owner  => $_consul_owner,
        group  => $_consul_group,
        mode   => '775',
        notify => Service['consul'],
      }
    }
    'windows': {
      file { "${_consul_data_dir}/logs":
        ensure => directory,
        owner  => $_consul_owner,
        group  => $_consul_group,
        mode   => '775',
      }
    }
    default:{}
  }

  $manage_group = $facts['os']['family'] ? {
    'Suse'  => true,
    default => false,
  }

  $_consul_install = $facts['kernel'] ? {
    'Linux'   => 'url',
    'windows' => 'package',
  }

  class { 'consul':
    config_hash      => $config_hash_contents,
    install_method   => $_consul_install,
    extra_groups     => $extra_groups,
    group            => $_consul_group,
    manage_group     => $manage_group,
    purge_config_dir => false,
    pretty_config    => true,
    version          => $version,
  }

  tidy { 'consul services':
    path    => $_consul_conf_dir,
    matches => '*.json',
    recurse => 1,
    notify  => Service['consul'],
  }

  if $profile::server::params::fw {
    include profile::consul::firewall::common
  }
}
