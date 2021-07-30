# $host_check_interval and $host_retry_interval are in seconds
class profile::monitoring::icinga2::server(
  $accept_config       = true,
  $node_name           = $trusted['certname'],
  $icinga2_environment = $profile::monitoring::icinga2::common::icinga2_environment,
  $owner               = $profile::monitoring::icinga2::common::owner,
  $zone                = $profile::monitoring::icinga2::common::zone,
  $zone_nodes          = $profile::monitoring::icinga2::common::zone_nodes,
  $parent_zone         = $profile::monitoring::icinga2::common::parent_zone,
  $parent_nodes        = $profile::monitoring::icinga2::common::parent_nodes,
  $child_nodes         = $profile::monitoring::icinga2::common::child_nodes,
  $manage_database     = false,
  Integer[1] $host_max_check_attempts = 5,
  Integer[1] $host_check_interval = 30,
  Integer[1] $host_retry_interval = 30,
) inherits profile::monitoring::icinga2::common {

  include profile::monitoring::icinga2::common
  include profile::monitoring::icinga2::commands
  include profile::server::params

  if $profile::server::params::fw {
    include profile::monitoring::icinga2::server::fw
  }

  $constants = {
    'NodeName'        => $trusted['certname'],
    'PluginDir'       => $profile::monitoring::icinga2::common::plugin_dir,
    'PuppetPluginDir' => $profile::monitoring::icinga2::common::plops_plugin_dir,
  }

  $_parent_zone = $parent_zone ? {
    'undef' => undef,
    default => $parent_zone,
  }

  icinga2::object::host { $trusted['certname']:
    check_command      => 'dummy',
    display_name       => $facts['networking']['fqdn'],
    ipv4_address       => $facts['networking']['ip'],
    max_check_attempts => $host_max_check_attempts,
    check_interval     => $host_check_interval,
    retry_interval     => $host_retry_interval,
    action_url         => 'https://confluence.puppetlabs.com/display/SRE/Icinga2+checks+that+may+escalate#Icinga2checksthatmayescalate-Hostisdown',
    zone               => $_parent_zone,
    vars               => {
      'owner'                  => $owner,
      'group'                  => $facts['classification']['group'],
      'function'               => $facts['classification']['function'],
      'stage'                  => $facts['classification']['stage'],
      'operatingsystem'        => $facts['os']['name'],
      'is_virtual'             => $facts['is_virtual'],
      'virtual'                => $facts['virtual'],
      'role'                   => lookup('classes', Array[String], 'unique', [''])[0],
      'cluster_zone'           => $zone,
      'notification_period'    => $profile::monitoring::icinga2::common::notification_period,
      'escalate'               => $profile::monitoring::icinga2::common::escalate_host_alerts,
      'notify_chat'            => $profile::monitoring::icinga2::common::notify_chat,
      'create_incident_ticket' => $profile::monitoring::icinga2::common::ticket_host_alerts,
    },
  }

  if ($parent_zone != undef or $parent_zone != 'undef') and $parent_nodes != {} {
    icinga2::object::zone { $parent_zone:
      endpoints => keys($parent_nodes),
    }
    each($parent_nodes) |$node, $f| {
      if $facts['whereami'] == 'echonet' and $facts['classification']['function'] == 'satellite' {
        # Echonet satellite still needs to connect to the master
        # more secure zone connects to less secure zones
        icinga2::object::endpoint { $node:
          host => $f['fqdn'],
          tag  => ['parent'],
        }
      }
      else {
        icinga2::object::endpoint { $node:
          # Uncomment the "host" parameter here when choosing to have clients
          # directly connect to master/satellites
          #host => $f['fqdn'],
          tag  => ['parent'],
        }
      }
    }
    icinga2::object::zone { String($zone):
      endpoints => flatten([$zone_nodes,  $trusted['certname']]),
      parent    => $parent_zone,
    }
  }
  else {
    icinga2::object::zone { String($zone):
      endpoints => flatten([$zone_nodes,  $trusted['certname']]),
    }
  }

  icinga2::object::endpoint { $trusted['certname']:
    host    => $facts['networking']['fqdn'],
  }

  if $zone_nodes != [] {
    $zone_nodes.each |$node_name| {
      icinga2::object::endpoint { $node_name:
        host => $node_name,
      }
    }
  }

  class { 'icinga2':
    db_type           => 'pgsql',
    db_name           => $profile::monitoring::icinga2::common::application,
    db_user           => $profile::monitoring::icinga2::common::db_user,
    db_host           => $profile::monitoring::icinga2::common::db_host,
    db_port           => $profile::monitoring::icinga2::common::db_port,
    db_pass           => $profile::monitoring::icinga2::common::db_pass,
    manage_database   => $manage_database,
    manage_repos      => true,
    package_ensure    => $profile::monitoring::icinga2::common::package_ensure,
    use_debmon_repo   => false,
    default_features  => flatten([$profile::monitoring::icinga2::common::features_enabled, ['mainlog']]),
    purge_configs     => true,
    purge_confd       => true,
    install_plugins   => true,
    install_mailutils => false,
    config_template   => 'profile/monitoring/icinga2/icinga2.conf.erb',
    config_mode       => '0751',
    restart_cmd       => '/usr/sbin/service icinga2 reload',
  }

  # All Icinga2 servers should receive their plugins
  file { $profile::monitoring::icinga2::common::plops_plugin_dir:
    ensure  => directory,
    source  => 'puppet:///modules/profile/monitoring/icinga2/plugins',
    mode    => '0755',
    recurse => true,
    owner   => $profile::monitoring::icinga2::common::icinga2_user,
    group   => $profile::monitoring::icinga2::common::icinga2_user,
  }

    $ssldir = $settings::ssldir

  class  { 'icinga2::feature::api':
    cert_path       => "${profile::monitoring::icinga2::common::conf_dir}/pki/${trusted['certname']}.crt",
    key_path        => "${profile::monitoring::icinga2::common::conf_dir}/pki/${trusted['certname']}.pem",
    ca_path         => "${profile::monitoring::icinga2::common::conf_dir}/pki/ca.crt",
    crl_path        => false,
    accept_config   => $accept_config,
    accept_commands => true,
    manage_zone     => false,
  }

  file { 'icinga2-pki-ca':
    ensure => file,
    path   => "${profile::monitoring::icinga2::common::conf_dir}/pki/ca.crt",
    source => "${ssldir}/certs/ca.pem",
    owner  => $icinga2::config_owner,
    group  => $icinga2::config_group,
    mode   => '0640',
  }

  file { 'icinga2-pki-cert':
    ensure => file,
    path   => "${profile::monitoring::icinga2::common::conf_dir}/pki/${trusted['certname']}.crt",
    source => "${ssldir}/certs/${trusted['certname']}.pem",
    owner  => $icinga2::config_owner,
    group  => $icinga2::config_group,
    mode   => '0640',
  }

  file { 'icinga2-pki-key':
    ensure => file,
    path   => "${profile::monitoring::icinga2::common::conf_dir}/pki/${trusted['certname']}.pem",
    source => "${ssldir}/private_keys/${trusted['certname']}.pem",
    owner  => $icinga2::config_owner,
    group  => $icinga2::config_group,
    mode   => '0640',
  }

  icinga2::conf { 'templates':
    template => 'profile/monitoring/icinga2/templates.conf.erb',
  }

}
