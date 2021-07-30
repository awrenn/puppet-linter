class profile::dns::puppet_deploy {
  profile_metadata::service { $title:
    human_name => 'DNS deployment: exported resources',
    team       => itops,
  }

  Dns_record <<| |>> {
    provider  => bind,
    ddns_key  => '/etc/bind/keys.d/dhcp_updater',
  }

}
