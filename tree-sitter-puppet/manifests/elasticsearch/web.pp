class profile::elasticsearch::web {
  profile_metadata::service { $title:
    human_name        => 'Elasticsearch web interface',
    team              => dio,
    end_users         => [
      'infrastructure-user@puppet.com',
      'discuss-sre@puppet.com',
    ],
    escalation_period => '24x7',
    downtime_impact   => "Users can't search Elasticsearch.",
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/Elasticsearch',
    ],
  }

  include profile::elasticsearch::common
  include profile::logging::logstashforwarder
  include profile::logging::web

  ::logstashforwarder::file { 'es_web_logs':
    paths  => [ '/var/log/elasticsearch/plops_requests.log' ],
    fields => { 'type' => 'es_web_logs' },
  }
  @@haproxy::balancermember { "${fqdn}-elasticsearch-9200_${facts['classification']['stage']}":
    listening_service => "logstash-elasticsearch-9200_${facts['classification']['stage']}",
    server_names      => $facts['networking']['hostname'],
    ipaddresses       => $facts['networking']['ip'],
    ports             => '9200',
    options           => 'check',
  }
  @@haproxy::balancermember { "${fqdn}-elasticsearch-9300_${facts['classification']['stage']}":
    listening_service => "logstash-elasticsearch-9300_${facts['classification']['stage']}",
    server_names      => $facts['networking']['hostname'],
    ipaddresses       => $facts['networking']['ip'],
    ports             => '9300',
    options           => 'check',
  }

  file { $::profile::elasticsearch::common::data_dir:
    ensure  => 'directory',
    mode    => '0744',
    recurse => true,
  }

  $es_web_config = {
    'node'                   => {
      'data' => 'false',
      'http' => 'true',
    },
    'path'                   => {
        'data' => $::profile::elasticsearch::common::data_dir,
    },
    'http.cors.enabled'      => true,
    'http.cors.allow-origin' => '/.*/',
  }

  ::elasticsearch::template { 'template_logstash':
    ensure => present,
    file   => 'puppet:///modules/profile/elasticsearch/template.json',
  }

  ::elasticsearch::template { 'template_logspout':
    ensure => present,
    file   => 'puppet:///modules/profile/elasticsearch/logspout_template.json',
  }

  ::elasticsearch::template { 'puppet_template':
    ensure => present,
    file   => 'puppet:///modules/profile/elasticsearch/puppet_template.json',
  }

  ::elasticsearch::template { 'zpr_template':
    ensure => present,
    file   => 'puppet:///modules/profile/elasticsearch/zpr_template.json',
  }

  ::elasticsearch::template { 'netflow_template':
    ensure => present,
    file   => 'puppet:///modules/profile/elasticsearch/netflow_template.json',
  }


  file { '/opt/rollup.py':
    ensure => present,
    source => 'puppet:///modules/profile/elasticsearch/rollup.py',
  }

  $new_config = deep_merge($::profile::elasticsearch::common::es_config, $es_web_config)

  class { '::elasticsearch':
    manage_repo   => true,
    init_defaults => $::profile::elasticsearch::common::init_default_settings,
    config        => $new_config,
    repo_version  => $::profile::elasticsearch::common::es_repo_version,
    version       => $::profile::elasticsearch::common::es_version,
    java_install  => $::profile::elasticsearch::common::es_java_install,
    logging_file  => 'puppet:///modules/profile/elasticsearch/logging-web.yml',
  }

  elasticsearch::instance { 'plops':
    config        => $new_config,
    init_defaults => $::profile::elasticsearch::common::init_default_settings,
    logging_file  => 'puppet:///modules/profile/elasticsearch/logging-data.yml',
  }

  # Rotate logs
  logrotate::job { 'elasticsearch-web':
    log     => '/var/log/elasticsearch/plops/plops*.log',
    options => [
      'daily',
      'copytruncate',
      'missingok',
      'rotate 7',
      'compress',
      'delaycompress',
      'notifempty',
    ],
  }
}
