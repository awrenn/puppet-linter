#
# Class used for the web frontend of graphite
# Handles graphite-web and memcached
#
class profile::graphite::web {
  profile_metadata::service { $title:
    human_name        => 'Graphite web interface',
    team              => dio,
    end_users         => [
      'infrastructure-user@puppet.com',
      'discuss-sre@puppet.com',
    ],
    escalation_period => '24x7',
    downtime_impact   => "Users can't access metrics.",
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/Graphite+Service+Page',
    ],
  }

  include profile::graphite::common

  if $::profile::server::monitoring {
    include profile::graphite::monitor::web
  }

  $postgres_host = hiera('profile::graphite::grafana::db_host')

  class { '::graphite':

    gr_enable_carbon_cache    => false,
    gr_web_server             => 'none',
    gr_timezone               => 'America/Los_Angeles',
    gr_user                   => 'www-data',
    gr_group                  => 'www-data',
    gr_web_user               => 'www-data',
    gr_web_group              => 'www-data',
    gr_memcache_hosts         => ['127.0.0.1:11211'],
    gr_cluster_servers        => $::profile::graphite::common::cluster_servers_web,
    gr_manage_python_packages => false,
    manage_ca_certificate     => false,
    gr_django_db_engine       => 'django.db.backends.postgresql_psycopg2',
    gr_django_db_name         => 'graphite',
    gr_django_db_user         => 'graphite',
    gr_django_db_host         => $postgres_host,
    gr_django_db_port         => '5432',
    secret_key                => hiera('profile::graphite::secret_key'),

  }

  class { 'memcached':
    listen_ip => '127.0.0.1',
  }

  @@haproxy::balancermember {
    default:
      options      => "check cookie ${facts['networking']['hostname']}",
      server_names => "${facts['networking']['hostname']}",
      ipaddresses  => "${facts['networking']['ip']}",
      ports        => '80',
    ;
    ["${facts['networking']['fqdn']}_graphite_80"]:
      listening_service => 'graphite-80',
      options           => 'check',
    ;
    ["${facts['networking']['fqdn']}_grafana_80"]:
      listening_service => 'grafana-80',
    ;
    ["${facts['networking']['fqdn']}_grafana_8080"]:
      listening_service => 'grafana-8080',
      ports             => '8080',
    ;
    ["${facts['networking']['fqdn']}_grafana_3000"]:
      listening_service => 'grafana-3000',
      ports             => '3000',
    ;
  }
}
