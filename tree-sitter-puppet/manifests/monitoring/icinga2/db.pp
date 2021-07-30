class profile::monitoring::icinga2::db {
  profile_metadata::service { $title:
    human_name        => 'Icinga2 Master Database',
    owner_uid         => 'heath',
    team              => dio,
    end_users         => ['discuss-sre@puppet.com'],
    escalation_period => '24/7',
    downtime_impact   => "Hosts aren't monitored.",
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/Icinga2+Infrastructure',
      'https://confluence.puppetlabs.com/display/SRE/Icinga2',
    ],
  }

  class { 'postgresql::globals':
    version => '9.4',
  }
  class { 'postgresql::server':
    listen_addresses => '*',
    require          => Class['postgresql::globals'],
  }

  include profile::monitoring::icinga2::common
  include profile::monitoring::icinga2::server

  Postgresql::Server::Pg_hba_rule {
    type        => 'host',
    database    => $::profile::monitoring::icinga2::common::application,
    user        => $::profile::monitoring::icinga2::common::application,
    auth_method => 'md5',
  }

  if $::profile::monitoring::icinga2::common::web_nodes != undef {
    $node_ip_instances = query_facts("Class[Profile::Monitoring::Icinga2::Web] and stage=${::profile::monitoring::icinga2::common::icinga2_environment}", ['primary_ip'])
    if is_hash($node_ip_instances) {
      $node_ips = map(values($node_ip_instances)) |$x| { $x['primary_ip'] }
    } else {
      $node_ips = $node_ip_instances.map |$k, $v| { $v['primary_ip'] }
    }
    each (flatten([$node_ips, $facts['networking']['ip']])) |$ip| {
      postgresql::server::pg_hba_rule { "${ip}":
        address => "${ip}/32",
      }
    }
  } else {
    notify { 'no_icinga2_web_nodes':
      message => 'Warning: There are no nodes with Profile::Monitoring::Icinga2::Web in the specified environment. Pg_hba_rules will not be managed until at least one is available.',
    }
  }

  class { '::icinga2::database':
    manage_schema => true,
    require       => Postgresql::Server::Db[$::profile::monitoring::icinga2::common::application],
  }

  postgresql::server::db { $::profile::monitoring::icinga2::common::application:
    owner    => $::profile::monitoring::icinga2::common::db_user,
    user     => $::profile::monitoring::icinga2::common::db_user,
    password => postgresql_password($::profile::monitoring::icinga2::common::db_user,
                                    $::profile::monitoring::icinga2::common::db_pass),
    require  => Class['postgresql::server'],
  }
}
