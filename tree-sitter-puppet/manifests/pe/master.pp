# Class: profile::pe::master
#
# Profile to manage PE master settings that should only be applied 
# to the master and aren't managed by the puppet_enterprise modules 
# or by profile::pe::master_common
#
class profile::pe::master () inherits profile::base::puppet::params {
  profile_metadata::service { $title:
    human_name        => 'Puppet Master',
    team              => dio,
    end_users         => ['notify-infracore@puppet.com'],
    escalation_period => 'global-workhours',
    downtime_impact   => "Can't make changes to infrastructure",
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/SRE+Internal+Puppet+Infrastructure+Service+Docs',
    ],
  }

  include pe_databases
  include resource_api::server

  if $facts['whereami'] == 'aws_internal_net_vpc' {
    include profile::ssl::infc_aws_wildcard

    node_group { 'Agent specified environment':
      ensure               => present,
      description          => 'Allows all nodes to pick their own environment',
      environment          => 'agent-specified',
      override_environment => true,
      parent               => 'All Environments',
      rule                 => ['and',  ['~', 'name', '.+']],
    }
  }
  else {
    include profile::ssl::ops
  }

  if $facts['classification']['stage'] == 'test' {
    include profile::pe::master::csr_forwarding
  }

  Ssl::Cert <| |> ~> Service['pe-nginx']
}
