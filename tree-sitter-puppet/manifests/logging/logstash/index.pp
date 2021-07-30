class profile::logging::logstash::index {

  include profile::logging::logstash

  # commenting out on 10 Jan 2020 due to geoip updating not working - Gene Liverman
  # class { '::profile::geoip':
  #   install_dir => '/etc/logstash',
  #   require     => Package['logstash'],
  # }

  $lumberjack_port = hiera('logstash::lumberjack::port')
  $aws_key_id = hiera('profile::logging::logstash::index::aws_key_id')
  $aws_secret_access_key = hiera('profile::logging::logstash::index::aws_secret_access_key')

  $ssldir = '/etc/puppetlabs/puppet/ssl'
  $cert_path = "${::logstash::params::installpath}/${trusted['certname']}.crt"
  $key_path = "${::logstash::params::installpath}/${trusted['certname']}.pem"

  @@haproxy::balancermember { "${facts['networking']['fqdn']}-logstash-forwarder":
    listening_service => "logstash-forwarder-12002_${facts['classification']['stage']}",
    server_names      => $facts['networking']['hostname'],
    ipaddresses       => $facts['networking']['ip'],
    ports             => $lumberjack_port,
    options           => 'check',
  }

  @@haproxy::balancermember { "${facts['networking']['fqdn']}-logspout-input":
    listening_service => "logspout_5000_${facts['classification']['stage']}",
    server_names      => $facts['networking']['hostname'],
    ipaddresses       => $facts['networking']['ip'],
    ports             => '5000',
    options           => 'check',
  }

  @@haproxy::balancermember { "${facts['networking']['fqdn']}-qaelk-input":
    listening_service => "qaelk_27182_${facts['classification']['stage']}",
    server_names      => $facts['networking']['hostname'],
    ipaddresses       => $facts['networking']['ip'],
    ports             => '27182',
    options           => 'check',
  }

  file { 'logstash-pki-cert':
    ensure => file,
    path   => $cert_path,
    source => "${ssldir}/certs/${trusted['certname']}.pem",
    owner  => $::profile::logging::logstash::service_user,
    group  => $::profile::logging::logstash::service_group,
    mode   => '0640',
  }

  file { 'logstash-pki-key':
    ensure => file,
    path   => $key_path,
    source => "${ssldir}/private_keys/${trusted['certname']}.pem",
    owner  => $::profile::logging::logstash::service_user,
    group  => $::profile::logging::logstash::service_group,
    mode   => '0640',
  }

  $input_logspout_config = @("INPUT_LOGSPOUT_CONFIG")
    input {
      tcp {
        port  => 5000
        codec => "json"
        type  => "logspout"
      }
    }
    | INPUT_LOGSPOUT_CONFIG

  logstash::configfile { 'input_logspout':
    content => $input_logspout_config,
    order   => 1,
  }

  $input_qaelk_config = @("INPUT_QAELK_CONFIG")
    input {
      http {
        port  => 27182
        type  => "qaelk"
      }
    }
    | INPUT_QAELK_CONFIG

  logstash::configfile { 'input_qaelk':
    content => $input_qaelk_config,
    order   => 1,
  }

  $input_lumberjack_config = @("INPUT_LUMBERJACK_CONFIG")
    input {
      lumberjack {
        port            => 12002
        ssl_key         => "${key_path}"
        ssl_certificate => "${cert_path}"
      }
    }
    | INPUT_LUMBERJACK_CONFIG

  logstash::configfile { 'input_lumberjack':
    content => $input_lumberjack_config,
    order   => 1,
  }

  $input_s3_config = @(INPUT_S3_CONFIG)
    <%- | String $s3_bucket,
          String $doc_type,
    | -%>
    input {
      s3 {
        bucket          => "<%= $s3_bucket %>"
        credentials     => "/opt/aws_creds"
        type            => "<%= $type %>"
        region          => "us-east-1"
        region_endpoint => "us-east-1"
      }
    }
    | INPUT_S3_CONFIG

  $s3_logging_buckets = {
    'pe-education-vms-logs2' => 's3_access',
    'puppetcast_logs'        => 's3_access',
    'pl-tops-cloudtrail'     => 'cloudtrail',
  }

  $s3_logging_buckets.each |$bucket, $type| {
    logstash::configfile { "input_s3_${bucket}":
      content =>  inline_epp($input_s3_config, { s3_bucket => $bucket, doc_type => $type }),
      order   => 1,
    }
  }

  $filters = [
    'delivery_foss_downloads',
    'delivery_pe_access',
    'delivery_pe_legacy_downloads',
    'json-event1',
    'nginx_access_json',
    'qaelk_xml',
    's3_access',
    'vmpooler',
    'unattended_upgrades',
  ]

  $filters.each |$filter| {
    logstash::configfile { "filter_${filter}":
      content => template("profile/logstash/filters/filter_${filter}.conf.erb"),
      order   => 50,
    }
  }

  logstash::plugin { 'logstash-filter-de_dot': }

  file { '/opt/aws_creds':
    ensure  => present,
    content => template('profile/logstash/aws_creds.erb'),
  }
}
