class profile::monitoring::icinga2::satellite inherits ::profile::monitoring::icinga2::common {

  profile_metadata::service { $title:
    human_name        => 'Icinga2 Satellite',
    owner_uid         => 'heath',
    team              => dio,
    end_users         => ['discuss-sre@puppet.com'],
    escalation_period => '24/7',
    downtime_impact   => "Hosts aren't monitored.",
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/Icinga2+Infrastructure',
      'https://confluence.puppetlabs.com/display/SRE/Icinga2',
    ],
    notes             => @("NOTES"),
      The satellite collects metrics from its subzone and reports them up to
      the parent zone's satellite or the master.
      |-NOTES
  }

  require profile::monitoring::icinga2::server

  # Allow QA and forge-admins ssh access to Icinga2 nodes for testing.
  ssh::allowgroup { [ 'forge-admins' ]: }
  sudo::allowgroup { 'forge-admins': }
  Account::User <| groups == 'forge-admins' |>

  # Check command dependencies for satellites

  # aggregated check and dependencies
  # see https://github.com/danieldreier/icinga2-aggregated-check for source
  # and build/usage instructions
  include profile::erlang
  package {'aggregated-check':
    ensure => latest,
  }

  # Hacky workaround to put certname fact on these agents
  file {'/etc/puppetlabs/facter':
    ensure => 'directory',
  }

  file {'/etc/puppetlabs/facter/facts.d':
    ensure => 'directory',
  }

  file {'/etc/puppetlabs/facter/facts.d/certname.txt':
    ensure  => 'present',
    content => "certname=${facts['networking']['fqdn']}",
  }

  # Needed for check-jira-auth
  python::pip { 'jira':
    ensure => '1.0.3',
  }

  python::pip { 'pytz':
    ensure => 'present',
  }

  # needed for cloudwatch check
  python::pip { ['boto','nagiosplugin']:
    ensure => 'present',
  }

  $ssh_private_key = hiera('profile::monitoring::icinga2::satellite::ssh_private_key', undef)
  if $ssh_private_key == undef {
    notify { 'There is no private ssh key for the monitoring user.': }
  }

  # This path is hard coded because the satellites only exist on Debian nodes and ssh checks are temporary
  file { '/var/lib/nagios/.ssh':
    ensure => directory,
    mode   => '0700',
    owner  => 'nagios',
    group  => 'nagios',
  }

  file { '/var/lib/nagios/.ssh/config':
    ensure  => present,
    mode    => '0644',
    owner   => 'nagios',
    group   => 'nagios',
    content => template('profile/monitoring/icinga2/satellite/ssh_config.erb'),
  }

  file { '/var/lib/nagios/.ssh/id_rsa':
    ensure  => present,
    mode    => '0600',
    owner   => 'nagios',
    group   => 'nagios',
    content => $ssh_private_key,
    require => File['/var/lib/nagios/.ssh'],
  }

  package { 'httpclient':
    ensure   => present,
    provider => 'gem',
  }

  # Singletons are used for running non-host specific checks on the satellite servers,
  # such as checking puppetlabs.com
  $combined_singleton = $::profile::monitoring::icinga2::common::child_nodes + $::profile::monitoring::icinga2::common::zone_instances
  $singleton_instances = flatten($combined_singleton.map |$node| {
    $node_results = query_resources("certname='${node['certname']}'", "@@Icinga2::Object::Service{tag='singleton'}")
  })
  if $singleton_instances != [] {
    $unique_titles = unique(map($singleton_instances) |$x| { $x['title'] })
    each($unique_titles) |$service_title| {
      $duplicate_services = filter($singleton_instances) |$s| { $s['title'] == $service_title }
      $unique_service = $duplicate_services[0]
      $node = filter($combined_singleton) |$n| { $n['certname'] == $unique_service['certname'] }
      if $unique_service['parameters']['zone'] == $node[0]['parameters']['zone'] {
        $service_zone = $::profile::monitoring::icinga2::common::zone
      } else {
        $service_zone = $unique_service['parameters']['zone']
      }
      icinga2::object::service { "singleton-${unique_service['title']}":
        target_file_name   => "${unique_service['title']}.conf",
        template_to_import => $unique_service['parameters']['template_to_import'],
        object_servicename => $unique_service['title'],
        display_name       => $unique_service['title'],
        host_name          => $::profile::monitoring::icinga2::common::master_host,
        groups             => $unique_service['parameters']['groups'],
        vars               => $unique_service['parameters']['vars'] + {
          'singleton source certname' => $unique_service['certname'],
        },
        check_command      => $unique_service['parameters']['check_command'],
        check_interval     => $unique_service['parameters']['check_interval'],
        max_check_attempts => $unique_service['parameters']['max_check_attempts'],
        action_url         => $unique_service['parameters']['action_url'],
        notes_url          => $unique_service['parameters']['notes_url'],
        retry_interval     => $unique_service['parameters']['retry_interval'],
        zone               => $service_zone,
      }
    }
  }

  # Add host definition for other satellites/masters in the same zone
  each($::profile::monitoring::icinga2::common::zone_nodes) |$node| {
    $hosts_results = query_resources(false,
                                    ['and',
                                    ['=', 'type', 'Icinga2::Object::Host'],
                                    ['=', 'title', $node],
                                    ['=', 'certname', $node]])
    if is_hash($hosts_results) {
      $hosts = flatten(values($hosts_results))
    } else {
      $hosts = $hosts_results.map |$k, $v| { $v }
    }
    each($hosts) |$host| {
      if $host['exported'] {
        $host_zone = $::profile::monitoring::icinga2::common::zone
        $host_check_command = $host['parameters']['check_command']
      } else {
        $host_check_command = $node ? {
          $host['title'] => 'cluster-zone',
          default        => 'dummy',
        }
        $host_zone = $host['parameters']['zone']
      }
      icinga2::object::host { $host['title']:
        ipv4_address         => $host['parameters']['ipv4_address'],
        display_name         => $host['parameters']['display_name'],
        enable_notifications => $host['parameters']['enable_notifications'],
        groups               => $host['parameters']['groups'],
        vars                 => $host['parameters']['vars'],
        target_file_name     => $host['parameters']['target_file_name'],
        max_check_attempts   => $host['parameters']['max_check_attempts'],
        check_interval       => $host['parameters']['check_interval'],
        retry_interval       => $host['parameters']['retry_interval'],
        zone                 => $host_zone,
        check_command        => $host_check_command,
      }
    }

  }

  each($::profile::monitoring::icinga2::common::child_nodes) |$node| {

    $zones_results = query_resources(false,
                                    ['and',
                                    ['=', 'type', 'Icinga2::Object::Zone'],
                                    ['=', 'certname', $node['certname']],
                                    ['not', ['=', 'title', $::profile::monitoring::icinga2::common::zone]]])
    if is_hash($zones_results) {
      $zones = flatten(values($zones_results))
    } else {
      $zones = $zones_results.map |$k, $v| { $v }
    }
    $hosts_results = query_resources(false,
                                    ['and',
                                    ['=', 'type', 'Icinga2::Object::Host'],
                                    ['=', 'certname', $node['certname']]])
    if is_hash($hosts_results) {
      $hosts = flatten(values($hosts_results))
    } else {
      $hosts = $hosts_results.map |$k, $v| { $v }
    }
    $services_results = query_resources(false,
                                        ['and',
                                        ['=', 'type', 'Icinga2::Object::Service'],
                                        ['=', 'certname', $node['certname']],
                                        ['not', ['=', 'tag', 'singleton']]])
    if is_hash($services_results) {
      $services = flatten(values($services_results))
    } else {
      $services = $services_results.map |$k, $v| { $v }
    }
    $child_endpoint_results = query_resources(false,
                                              ['and',
                                              ['=', 'type', 'Icinga2::Object::Endpoint'],
                                              ['=', 'certname', $node['certname']],
                                              ['not', ['=', 'tag', 'parent']],
                                              ['not', ['=', 'title', $trusted['certname']]]])

    if is_hash($child_endpoint_results) {
      $child_endpoints = flatten(values($child_endpoint_results))
    } else {
      $child_endpoints = $child_endpoint_results.map |$k, $v| { $v }
    }

    if $child_endpoints != [] {
      each($child_endpoints) |$endpoint| {
        icinga2::object::endpoint { $endpoint['title']:
          # Comment here to allow for masters/satellites to not connect to clients
          # Used for when clients connect to masters
          host => $endpoint['parameters']['host'],
        }
      }
    }
    each($hosts) |$host| {
      if $host['exported'] {
        $host_zone = $::profile::monitoring::icinga2::common::zone
        $host_check_command = $host['parameters']['check_command']
      } else {
        $host_check_command = $node['certname'] ? {
          $host['title'] => 'cluster-zone',
          default        => 'dummy',
        }
        $host_zone = $host['parameters']['zone']
      }
      icinga2::object::host { $host['title']:
        ipv4_address         => $host['parameters']['ipv4_address'],
        display_name         => $host['parameters']['display_name'],
        enable_notifications => $host['parameters']['enable_notifications'],
        groups               => $host['parameters']['groups'],
        vars                 => $host['parameters']['vars'],
        target_file_name     => $host['parameters']['target_file_name'],
        max_check_attempts   => $host['parameters']['max_check_attempts'],
        check_interval       => $host['parameters']['check_interval'],
        retry_interval       => $host['parameters']['retry_interval'],
        zone                 => $host_zone,
        check_command        => $host_check_command,
      }
    }

    each($services) |$service| {
      if $service['parameters']['object_servicename'] != undef {
        $service_name = $service['parameters']['object_servicename']
      }
      else {
        $service_name = $service['title']
      }
      if $service['exported'] {
        if $service['parameters']['zone'] == $node['parameters']['zone'] or
          $service['parameters']['check_command'] == 'by_ssh' {
          $service_zone = $::profile::monitoring::icinga2::common::zone
        } else {
          $service_zone = $service['parameters']['zone']
        }
      } else {
        $service_zone = $service['parameters']['zone']
      }
      icinga2::object::service { "${service['parameters']['host_name']}-${service_name}":
        object_servicename => $service_name,
        template_to_import => $service['parameters']['template_to_import'],
        display_name       => $service_name,
        host_name          => $service['parameters']['host_name'],
        groups             => $service['parameters']['groups'],
        vars               => $service['parameters']['vars'],
        check_command      => $service['parameters']['check_command'],
        event_command      => $service['parameters']['event_command'],
        check_interval     => $service['parameters']['check_interval'],
        max_check_attempts => $service['parameters']['max_check_attempts'],
        action_url         => $service['parameters']['action_url'],
        notes_url          => $service['parameters']['notes_url'],
        retry_interval     => $service['parameters']['retry_interval'],
        zone               => $service_zone,
      }
    }
    each($zones) |$zone| {
      icinga2::object::zone { $zone['title']:
        endpoints => flatten([$zone['parameters']['endpoints']]),
        parent    => $zone['parameters']['parent'],
      }
    }
  }
}
