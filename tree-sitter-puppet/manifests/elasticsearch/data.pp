class profile::elasticsearch::data {
  profile_metadata::service { $title:
    human_name        => 'Elasticsearch',
    team              => dio,
    end_users         => [
      'infrastructure-user@puppet.com',
      'discuss-sre@puppet.com',
    ],
    escalation_period => '24x7',
    downtime_impact   => "New logs are lost; users can't search Elasticsearch.",
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/Elasticsearch',
    ],
    notes             => @("NOTES"),
      Storage, indexing, and search of general data including logs.
      |-NOTES
  }

  include profile::elasticsearch::common

  $es_data_config = {
    'node'   => {
      'data' => 'true',
      'http' => 'false',
    },
    'indicies'                      => {
      'memory.index_buffer_size'    => '50%',
      'fielddata.cache.size'        => '75%',
      'breaker.fielddata.limit'     => '85%',
      'recovery.max_bytes_per_sec'  => '1g',
      'recovery.concurrent_streams' => 48,
    },
  }

  $new_config = deep_merge($::profile::elasticsearch::common::es_config, $es_data_config)
  class { '::elasticsearch':
    manage_repo   => true,
    config        => $new_config,
    init_defaults => $::profile::elasticsearch::common::init_default_settings,
    repo_version  => $::profile::elasticsearch::common::es_repo_version,
    version       => $::profile::elasticsearch::common::es_version,
    java_install  => $::profile::elasticsearch::common::es_java_install,
    logging_file  => 'puppet:///modules/profile/elasticsearch/logging-data.yml',
  }

  elasticsearch::instance { 'plops':
    config        => $new_config,
    init_defaults => $::profile::elasticsearch::common::init_default_settings,
    datadir       => $::profile::elasticsearch::common::data_dir,
    logging_file  => 'puppet:///modules/profile/elasticsearch/logging-data.yml',
  }
  # Rotate logs - manual-ish since elasticsearch daily rotates already
  # Want to remove all old log files, including gziped
  # Don't want to gzip gzip'd files however

  cron { 'remove old elasticsearch logs':
    command => '/usr/bin/find /var/log/elasticsearch/plops -name "*.log.*" -type f -mtime +30 -delete',
    user    => 'root',
    hour    => 0,
    minute  => 0,
  }
  cron { 'gzip elasticsearch logs':
    command => '/bin/gzip /var/log/elasticsearch/plops/*.log.????-??-??',
    user    => 'root',
    hour    => 1,
    minute  => 0,
  }
}
