# Class: profile::pe::master::metrics
#
# Configures metrics collection for PE Master-specific services.
#
class profile::pe::master::metrics (
  $graphite_host = 'graphite.ops.puppetlabs.net'
) {
  puppet_enterprise::pg::ordinary_user{ 'telegraf':
    user_name         => 'telegraf',
    database          => 'pe-puppetdb',
    database_password => '',
    write_access      => false,
    db_owner          => 'pe-postgres',
    replication_user  => 'pe-ha-replication',
  }

  puppet_enterprise::pg::ident_entry { 'telegraf':
    pg_ident_conf_path => "/opt/puppetlabs/server/data/postgresql/${facts['pe_postgresql_info']['installed_server_version']}/data/pg_ident.conf",
    database           => 'pe-puppetdb',
    ident_map_key      => 'pe-puppetdb-telegraf-map',
    client_certname    => $facts['networking']['fqdn'],
    user               => 'telegraf',
    notify             => Service['pe-postgresql'],
  }

  puppet_metrics_dashboard::profile::master::postgres{ $facts['networking']['fqdn']:
    query_interval => '10m',
  }
}
