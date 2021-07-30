# profile::consul::server
#
class profile::consul::server {
  profile_metadata::service { $title:
    human_name        => 'Consul Server',
    team              => 'dio',
    end_users         => ['notify-infracore@puppet.com'],
    escalation_period => 'pdx-workhours',
    downtime_impact   => @(END),
      Service discovery is interrupted which impacts getting nodes monitored and
      impacts some load balancers being populated (the PE load balancers are an example of this).
      | END
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/Consul',
    ],
  }

  include profile::consul

  case $facts['classification']['stage'] {
    'test': { $domain_value = 'consul-dev.puppet.net' }
    default: { $domain_value = 'consul.puppet.net' }
  }

  consul_key_value {
    default:
      ensure     => 'present',
      datacenter => lookup('profile::consul::datacenter'),
      require    => Class['consul'],
    ;
    'consul-dns/':
    ;
    'consul-dns/domain':
      value => $domain_value,
    ;
    'consul-dns/port':
      value => '53',
    ;
  }

  if $profile::server::params::fw {
    include profile::consul::firewall::server
  }
}
