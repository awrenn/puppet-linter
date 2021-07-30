class profile::graphite::server(
    $updates_per_second = '750',
    $disk_id            = 'sda'
) {
  profile_metadata::service { $title:
    human_name        => 'Graphite Whisper database',
    team              => dio,
    end_users         => [
      'infrastructure-user@puppet.com',
      'discuss-sre@puppet.com',
    ],
    escalation_period => '24x7',
    downtime_impact   => "New metrics are lost; users can't access metrics.",
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/Graphite+Service+Page',
    ],
  }

  include profile::graphite::common
  include profile::graphite::carbonate
  include supervisord

  # User for carbonate
  Account::User <| title == 'carbon' |>
  ssh::allowgroup { 'www-data': }

  # Manage statsd in supervisord
  supervisord::program { 'statsd':
    command     => '/usr/bin/node /opt/statsd/stats.js /opt/statsd/local.js',
    priority    => '100',
    autorestart => 'true',
    autostart   => true,
    user        => 'root',
  }

  $pickle_relay_destinations = ['127.0.0.1:2014:a'] + $::profile::graphite::common::cache_instances.map |$cache_name, $cache_value| {
    join(['127.0.0.1:', $cache_value['PICKLE_RECEIVER_PORT'], ':', split($cache_name,':')[1]],'')
  }

  $carbonlink_array = ['127.0.0.1:7002:a'] + $::profile::graphite::common::cache_instances.map |$cache_name, $cache_value| {
    join(['127.0.0.1:', $cache_value['CACHE_QUERY_PORT'], ':', split($cache_name,':')[1]],'')
  }

  class { '::graphite':

    gr_web_server                         => 'none',
    gr_timezone                           => 'America/Los_Angeles',
    manage_ca_certificate                 => false,
    gr_relay_max_queue_size               => '2000000',
    gr_max_cache_size                     => '25000000',
    gr_use_ldap                           => true,
    gr_ldap_uri                           => hiera('profile::graphite::ldap_uri'),
    gr_ldap_search_base                   => hiera('profile::graphite::ldap_search_base'),
    gr_ldap_base_user                     => hiera('profile::ldap::client::binddn'),
    gr_ldap_base_pass                     => unwrap(hiera('profile::ldap::client::sensitive_bindpw')),
    gr_ldap_user_query                    => '(uid=%s)',
    gr_max_updates_per_second             => $updates_per_second,
    gr_max_updates_per_second_on_shutdown => '50000',
    gr_user                               => 'www-data',
    gr_group                              => 'www-data',
    gr_web_user                           => 'www-data',
    gr_web_group                          => 'www-data',
    gr_max_creates_per_minute             => '100',
    gr_cache_write_strategy               => 'sorted',
    gr_log_listener_connections           => 'False',
    gr_use_whitelist                      => 'True',
    gr_whitelist                          => ['.*'],
    gr_blacklist                          => ['\.\.', '^\.', '\.$', 'evalbase64_decode'],
    gr_whisper_fallocate_create           => 'True',
    secret_key                            => hiera('profile::graphite::secret_key'),
    gr_line_receiver_interface            => '127.0.0.1',
    gr_pickle_receiver_interface          => '127.0.0.1',
    gr_cache_query_interface              => '127.0.0.1',
    gr_enable_carbon_relay                => true,
    gr_line_receiver_port                 => '2013',
    gr_udp_receiver_port                  => '2013',
    gr_pickle_receiver_port               => '2014',
    gr_relay_line_port                    => '2103',
    gr_relay_pickle_port                  => '2004',
    gr_cache_instances                    => $::profile::graphite::common::cache_instances,
    gr_relay_destinations                 => $pickle_relay_destinations,
    gr_relay_method                       => 'consistent-hashing',
    gr_relay_log_listener_connections     => 'False',
    gr_carbonlink_hosts                   => $carbonlink_array,
    gr_carbonlink_query_bulk              => 'True',
    gr_cluster_servers                    => $::profile::graphite::common::cluster_servers_web,
    gr_storage_schemas                    => $::profile::graphite::common::schema,
    gr_storage_aggregation_rules          => {
    '00_min'         => { pattern => '\.min$',          factor => '0.1', method => 'min' },
    '01_max'         => { pattern => '\.max$',          factor => '0.1', method => 'max' },
    '02_sum'         => { pattern => '\.count$',        factor => '0.1', method => 'sum' },
    '03_puppet'      => { pattern => 'puppet.*',        factor => '0',   method => 'average' },
    '04_min'         => { pattern => '\.lower$',        factor => '0.1', method => 'min' },
    '05_max'         => { pattern => '\.upper(_\d+)?$', factor => '0.1', method => 'max' },
    '06_legacy'      => { pattern => '^stats_counts.*', factor => '0',   method => 'sum' },
    '07_vmpooler'    => { pattern => 'vmpooler.*',      factor => '0',   method => 'average' },
    '99_default_avg' => { pattern => '.*',              factor => '0.5', method => 'average' },
    },
    gr_manage_python_packages             => false,
  }

  if $::profile::server::monitoring {
    include profile::graphite::monitor::backend
  }

  # Sysctl tuning to reduce constant memory flushing
  sysctl::value { 'vm.dirty_background_ratio':
    value => 30,
  }
  sysctl::value { 'vm.dirty_ratio':
    value => 60,
  }
  sysctl::value { 'vm.dirty_expire_centisecs':
    value => 108000,
  }
  # Set io scheduler to deadline
  exec { 'io_scheduler_deadline':
    command => "/bin/echo deadline > /sys/block/${disk_id}/queue/scheduler",
    unless  => join(['/bin/grep \'\[deadline\]\' /sys/block/', $disk_id, '/queue/scheduler 2>&1 >/dev/null']),
  }

  $carbon_c_cache_array = [join([$::graphite::gr_line_receiver_interface,':',$::graphite::gr_line_receiver_port,'=a'], '')] + $::profile::graphite::common::cache_instances.map |$cache_name, $cache_value| {
    join(['127.0.0.1:', $cache_value['LINE_RECEIVER_PORT'], '=', split($cache_name,':')[1]],'')
  }
  class { 'profile::graphite::carbon_c_relay':
    queue_size          => 45000000,
    carbon_c_relay_dest => $carbon_c_cache_array,
  }

  cron { 'cleanup dead graphite data':
    command => '/usr/bin/find /opt/graphite/storage/whisper -name "*.wsp" -mtime +14 -exec rm -f {} \;',
    minute  => fqdn_rand(60),
    hour    => 10,
  }

  cron { 'cleanup dead graphite keys':
    command => '/usr/bin/find /opt/graphite/storage/whisper -type d -empty -exec rmdir {} \;',
    minute  => fqdn_rand(60),
    hour    => 11,
  }

  telegraf::input { 'prometheus-graphite_exporter':
    plugin_type => 'prometheus',
    options     => [{
      'urls' => [
        'http://localhost:9108/metrics',
      ],
    }],
  }

}
