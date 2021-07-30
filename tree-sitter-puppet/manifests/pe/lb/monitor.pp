# Class: profile::pe::lb::monitoring
#
# Configuring monitoring for HAProxy on PE load balancers.
#
class profile::pe::lb::monitor(
  String[1] $puppet_cname = 'puppet.ops.puppetlabs.net',
) inherits profile::monitoring::icinga2::common {

  $base_check_doc_link = 'https://confluence.puppetlabs.com/display/SRE/Service+Checks+for+the+SRE+Internal+Puppet+Infrastructure#ServiceChecksfortheSysOpsInternalPuppetInfrastructure'

  # TODO: these should have dependencies on the haproxy service.
  @@icinga2::object::service { "${puppet_cname}_http":
    check_command => 'http',
    action_url    => "${base_check_doc_link}-PuppetCAHTTPSCheck",
    vars          => {
      http_address => $puppet_cname,
      http_port    => 8140,
      http_ssl     => true,
      http_uri     => '/puppet/v3/status/foo?environment=production',
      http_header  => 'Accept: */*',
      escalate     => true,
    },
    tag           => ['singleton'],
  }

  icinga2::object::service { 'puppet_lb_http':
    check_command => 'http',
    action_url    => "${base_check_doc_link}-PuppetServerHTTPSCheck.2",
    vars          => {
      http_address => $facts['networking']['ip'],
      http_port    => 8140,
      http_ssl     => true,
      http_uri     => '/puppet/v3/status/foo?environment=production',
      escalate     => true,
    },
  }

  icinga2::object::service { 'puppet_lb_haproxy':
    check_command => 'check-service-status',
    action_url    => "${base_check_doc_link}-HAProxyservicecheck",
    vars          => {
      service => 'rh-haproxy18-haproxy',
    },
  }
}
