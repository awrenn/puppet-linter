class profile::logging::logstash {
  profile_metadata::service { $title:
    human_name        => 'Logstash indexer',
    team              => dio,
    end_users         => [
      'infrastructure-user@puppet.com',
      'discuss-sre@puppet.com',
    ],
    escalation_period => '24x7',
    downtime_impact   => 'New logs are lost.',
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/Logstash+Infrastructure',
      'https://confluence.puppetlabs.com/display/SRE/Logstash+User+Docs',
      'https://confluence.puppetlabs.com/display/SRE/Troubleshooting+Logstash',
      'https://confluence.puppetlabs.com/display/SRE/Creating+a+new+filter+for+logstash',
    ],
  }

  $heap_size = hiera('profile::logging::logstash::heap_size')
  $open_files = hiera('profile::logging::logstash::open_files')
  $niceness = hiera('profile::logging::logstash::niceness')

  $es_host = hiera('elasticsearch::host')
  $es_cluster = hiera('elasticsearch::cluster')
  $service_user = 'logstash'
  $service_group = 'logstash'

  $qaelk_password = hiera('qaelk::readwrite::password')

  class { '::logstash':
    manage_repo   => true,
    repo_version  => '2.3',
    status        => 'enabled',
    java_install  => true,
    init_defaults => {
      'LS_HEAP_SIZE'  => "\"${heap_size}\"",
      'LS_OPEN_FILES' => $open_files,
      'LS_NICE'       => $niceness,
      'LS_USER'       => $service_user,
      'LS_GROUP'      => $service_group,
    },
  }

  $patterns = [
    'custom_nginx_lb_access',
    'drupal_log',
    'srx_log',
    'slapd_log',
    'vmpooler',
  ]

  $patterns.each |$pattern| {
    logstash::patternfile { "pattern_${pattern}":
      source => "puppet:///modules/profile/logstash/patterns/pattern_${pattern}",
    }
  }

  logstash::configfile { 'filter_syslog':
    content => template('profile/logstash/filters/filter_syslog.conf.erb'),
    order   => 50,
  }

  $output_type_es_output_config = @(OUTPUT_TYPE_ES_CONFIG)
    <%- | String $es_host,
          String $doc_type,
          String $index,
          Optional[String] $user = undef,
          Optional[String] $password = undef,
          Optional[String] $template = undef,
          Optional[Boolean] $template_overwrite = undef,
    | -%>
    output {
      if [type] == "<%= $doc_type %>" {
        elasticsearch {
          hosts           => [ "<%= $es_host %>" ]
          manage_template => false
          workers         => 2
          index           => "<%= $index %>"
    <% unless $user =~ Undef { -%>
          user            => "<%= $user %>"
          password        => "<%= $password %>"
    <% } -%>
    <% unless $template =~ Undef { -%>
          template           => "<%= $template %>"
    <% } -%>
    <% unless $template_overwrite =~ Undef { -%>
          template_overwrite => "<%= $template_overwrite %>"
    <% } -%>
        }
      }
    }
    | OUTPUT_TYPE_ES_CONFIG

  $output_es_config = @(OUTPUT_ES_CONFIG)
    <%- | String $es_host | -%>
    output {
      if [type] != 'logspout' and [type] != 'qaelk' {
        elasticsearch {
          hosts           => [ "<%= $es_host %>" ]
          manage_template => false
          workers         => 2
        }
      }
    }
    | OUTPUT_ES_CONFIG

  # The elasticsearch_test_host variable is a fact which can be set when running Puppet in order to temporarily set up a Logstash output to a test instance of Elasticsearch.
  if $::elasticsearch_test_host {
    logstash::configfile { 'output_es_http_test':
      content => inline_epp($output_es_config, { es_host => $::elasticsearch_test_host }),
      order   =>  99,
    }
  }

  logstash::configfile { 'output_es':
    content =>   inline_epp($output_es_config, { es_host => $es_host }),
    order   =>  99,
  }

  logstash::configfile { 'logspout_es_output':
    content => inline_epp($output_type_es_output_config, { es_host => $es_host, doc_type => 'logspout', index => 'logspout-%{+YYYY.MM}' }),
    order   => 99,
  }

  # JSON elasticsearch index templates
  $logstash_managed_es_templates_dir = '/var/lib/logstash/es_templates'
  file { $logstash_managed_es_templates_dir:
    ensure  => directory,
    mode    => '0750',
    owner   => 'logstash',
    group   => 'logstash',
    recurse => true,
    purge   => true,
    force   => true,
    source  => 'puppet:///modules/profile/logstash/es_templates',
  }

  $qaelk_es_template_file = "${logstash_managed_es_templates_dir}/qaelk_es_template_acceptance.json"
  logstash::configfile { 'qaelk_es_output':
    content => inline_epp($output_type_es_output_config, { es_host => 'https://dc98726059d05da4448aeed2272052b6.us-west-2.aws.found.io:9243', user => 'readwrite', password => $qaelk_password, doc_type => 'qaelk', index => 'acceptance-%{+YYYY.MM.dd}', template => $qaelk_es_template_file, template_overwrite => true}),
    order   => 99,
  }
}
