class profile::graphite::relay () inherits ::profile::graphite::params {
  profile_metadata::service { $title:
    human_name        => 'Graphite relay',
    team              => dio,
    end_users         => [
      'infrastructure-user@puppet.com',
      'discuss-sre@puppet.com',
    ],
    escalation_period => '24x7',
    downtime_impact   => 'New metrics are lost.',
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/Graphite+Service+Page',
    ],
  }

  include profile::graphite::common

  class { '::graphite':
    gr_timezone               => 'America/Los_Angeles',
    manage_ca_certificate     => false,
    gr_relay_max_queue_size   => '4000000',
    gr_use_ldap               => true,
    gr_enable_carbon_cache    => false,
    gr_user                   => $::profile::graphite::params::relay_web_user,
    gr_group                  => $::profile::graphite::params::relay_web_group,
    secret_key                => hiera('profile::graphite::secret_key'),
    gr_line_receiver_port     => '2013',
    gr_enable_carbon_relay    => true,
    gr_udp_receiver_port      => '2013',
    gr_pickle_receiver_port   => '2014',
    gr_relay_line_port        => '2103',
    gr_relay_pickle_port      => '2004',
    gr_relay_method           => 'consistent-hashing',
    gr_relay_destinations     => $::profile::graphite::common::cluster_servers_2004,
    gr_manage_python_packages => false,
  }

  if $::profile::server::monitoring {
    include profile::graphite::monitor::relay
  }

  # Carbon-c-relay for line receiver
  class { 'profile::graphite::carbon_c_relay':
    queue_size          => 4000000,
    carbon_c_relay_dest => $::profile::graphite::common::cluster_servers_2003,
  }

  if $facts['classification']['stage'] == 'prod' {
    @@haproxy::balancermember { "${facts['networking']['fqdn']}_graphite_2003":
      listening_service => 'graphite-2003',
      server_names      => "${facts['networking']['hostname']}",
      ipaddresses       => "${facts['networking']['ip']}",
      ports             => '2003',
      options           => 'check',
    }

    @@haproxy::balancermember { "${facts['networking']['fqdn']}_graphite_2004":
      listening_service => 'graphite-2004',
      server_names      => "${facts['networking']['hostname']}",
      ipaddresses       => "${facts['networking']['ip']}",
      ports             => '2004',
      options           => 'check',
    }
  }
}
