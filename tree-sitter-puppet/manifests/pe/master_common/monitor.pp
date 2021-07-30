# Class: profile::pe::master_common::monitor
#
# Configures checks for PE master services.
#
class profile::pe::master_common::monitor inherits profile::monitoring::icinga2::common {
  $base_check_doc_link = 'https://confluence.puppetlabs.com/display/SRE/Service+Checks+for+the+SRE+Internal+Puppet+Infrastructure#ServiceChecksfortheSysOpsInternalPuppetInfrastructure'

  # TODO: this should have a service dependency on the system service below.
  icinga2::object::service { 'puppet_master_http':
    check_command => 'http',
    action_url    => "${base_check_doc_link}-PuppetServerHTTPSCheck.1",
    vars          => {
      http_address   => $facts['networking']['ip'],
      http_port      => 8140,
      http_ssl       => true,
      http_uri       => '/puppet/v3/status/foo?environment=production',
      parent_service => 'puppet_master_pe-puppetserver',
    },
  }

  @@icinga2::object::service { 'aggregated_puppet_master_http':
    check_command => 'aggregated-check',
    action_url    => "${base_check_doc_link}-AggregatedPuppetServerHTTPSCheck",
    vars          => {
      icinga_service_filter => 'service.name == "puppet_master_http"',
      check_name            => 'aggregated_puppet_master_http',
      icinga_api_username   => 'icinga2',
      icinga_api_password   => lookup('icinga2_apiuser_pass'),
      check_state           => 'critical',
      warn_threshold        => '2',
      crit_threshold        => '4',
      threshold_order       => 'max',
      escalate              => true,
    },
    tag           => ['singleton'],
  }

  icinga2::object::service { 'puppet_master_pe-puppetserver':
    check_command => 'check-service-status',
    action_url    => "${base_check_doc_link}-PuppetServerservicecheck",
    vars          => {
      service  => 'pe-puppetserver',
      escalate => true,
    },
  }

  icinga2::object::service { 'puppet_master_check_environments':
    check_command => 'check-puppet-environments',
    action_url    => "${base_check_doc_link}-Puppetenvironmentscheck",
    vars          => {
      escalate => true,
    },
  }
}
