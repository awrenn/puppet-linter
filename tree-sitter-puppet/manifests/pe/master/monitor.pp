# Class: profile::pe::master::monitor
#
# Configures Master-specific monitoring checks.
#
class profile::pe::master::monitor(
  String[1] $puppetca_cname = 'puppet.ops.puppetlabs.net',
  String[1] $peconsole_cname = 'peconsole.ops.puppetlabs.net',
) inherits profile::monitoring::icinga2::common {

  $base_check_doc_link = 'https://confluence.puppetlabs.com/display/SRE/Service+Checks+for+the+SRE+Internal+Puppet+Infrastructure#ServiceChecksfortheSysOpsInternalPuppetInfrastructure'
  $notification_period = $profile::monitoring::icinga2::common::notification_period

  # TODO: these should have service dependencies on the OS services below.
  @@icinga2::object::service { "${puppetca_cname}_http":
    check_command => 'http',
    action_url    => "${base_check_doc_link}-PuppetCACNAMEHTTPSCheck",
    vars          => {
      http_address        => $puppetca_cname,
      http_port           => 8140,
      http_ssl            => true,
      http_uri            => '/puppet/v3/status/foo?environment=production',
      http_header         => 'Accept: */*',
      notification_period => $notification_period,
    },
    tag           => ['singleton'],
  }

  @@icinga2::object::service { "${peconsole_cname}_http_console":
    check_command => 'http',
    action_url    => "${base_check_doc_link}-PEConsoleCNAMEHTTPSCheck",
    vars          => {
      http_address        => $peconsole_cname,
      http_port           => 443,
      http_ssl            => true,
      notification_period => $notification_period,
    },
    tag           => ['singleton'],
  }

  icinga2::object::service { 'puppet_mom_http':
    check_command => 'http',
    action_url    => "${base_check_doc_link}-PuppetServerHTTPSCheck",
    vars          => {
      http_address        => $facts['networking']['ip'],
      http_port           => 8140,
      http_ssl            => true,
      http_uri            => '/puppet/v3/status/foo?environment=production',
      notification_period => $notification_period,
    },
  }

  icinga2::object::service { 'puppet_mom_http_console':
    check_command => 'http',
    action_url    => "${base_check_doc_link}-PEConsoleHTTPSCheck",
    vars          => {
      http_address        => $facts['networking']['ip'],
      http_port           => 443,
      http_ssl            => true,
      escalate            => true,
      notification_period => $notification_period,
    },
  }

  icinga2::object::service { 'puppet_mom_http_console_status':
    check_command => 'http',
    action_url    => "${base_check_doc_link}-PEConsolestatuscheck",
    vars          => {
      http_address        => $facts['networking']['ip'],
      http_port           => 4433,
      http_ssl            => true,
      http_uri            => '/status/v1/services',
      http_clientcert     => "${profile::monitoring::icinga2::common::conf_dir}/pki/${trusted['certname']}.crt",
      http_privatekey     => "${profile::monitoring::icinga2::common::conf_dir}/pki/${trusted['certname']}.pem",
      escalate            => true,
      notification_period => $notification_period,
    },
  }

  icinga2::object::service { 'puppet_mom_http_puppetdb':
    check_command => 'http',
    action_url    => "${base_check_doc_link}-PuppetDBHTTPSCheck",
    vars          => {
      http_address        => $facts['networking']['ip'],
      http_port           => 8081,
      http_ssl            => true,
      http_uri            => '/pdb/meta/v1/version',
      http_clientcert     => "${profile::monitoring::icinga2::common::conf_dir}/pki/${trusted['certname']}.crt",
      http_privatekey     => "${profile::monitoring::icinga2::common::conf_dir}/pki/${trusted['certname']}.pem",
      escalate            => true,
      notification_period => $notification_period,
    },
  }

  icinga2::object::service { 'puppet_mom_puppetdb_report':
    check_command => 'check_pdb_report_time',
    action_url    => "${base_check_doc_link}-PEMasterofMastersPuppetDBreporttimecheck",
    vars          => {
      host                => $trusted['certname'],
      escalate            => true,
      notification_period => $notification_period,
      parent_service      => 'puppet_mom_http_puppetdb',
      warn_minutes        => 721,
      critical_minutes    => 1441,
    },
  }

  icinga2::object::service { 'puppet_mom_pe-console-services':
    check_command => 'check-service-status',
    action_url    => "${base_check_doc_link}-PEMasterofMastersservicechecks",
    vars          => {
      service             => 'pe-console-services',
      escalate            => true,
      notification_period => $notification_period,
    },
  }

  icinga2::object::service { 'puppet_mom_pe-puppetdb':
    check_command => 'check-service-status',
    action_url    => "${base_check_doc_link}-PEMasterofMastersservicechecks",
    vars          => {
      service             => 'pe-puppetdb',
      escalate            => true,
      notification_period => $notification_period,
    },
  }

  icinga2::object::service { 'puppet_mom_pe-postgresql':
    check_command => 'check-service-status',
    action_url    => "${base_check_doc_link}-PEMasterofMastersservicechecks",
    vars          => {
      service             => 'pe-postgresql',
      escalate            => true,
      notification_period => $notification_period,
    },
  }

  icinga2::object::service { 'puppet_mom_pe-nginx':
    check_command => 'check-service-status',
    action_url    => "${base_check_doc_link}-PEMasterofMastersservicechecks",
    vars          => {
      service             => 'pe-nginx',
      escalate            => true,
      notification_period => $notification_period,
    },
  }
}
