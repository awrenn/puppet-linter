class profile::dns::server (
  $forward_zones = []
) {
  profile_metadata::service { $title:
    human_name => 'Internal DNS server',
    team       => itops,
    doc_urls   => [
      'https://confluence.puppetlabs.com/display/IT/DNS+Service',
    ],
  }

  include profile::dns::common
  if $::profile::server::params::monitoring {
    include profile::dns::monitor
  }

  # Find zone this host is in
  # Extra test case for pdx since we don't have a pdx_test whereami
  if $::whereami == 'pdx' {
    if $facts['networking']['ip'] =~ '^10\.28\.' {
      $location = 'pdx_test'
    }
    else {
      $location = $::whereami
    }
  } else {
    $location = $::whereami
  }

  # Wall of comments to explain what's happening here.
  # We create an array of hashes from hiera, and start to parse information out of it, what
  # we're looking for is an array of every master (net01) and slave (net02) ip address, excluding
  # the address of the host we're on - we don't notify ourselves about dns changes
  #
  # master_ip_array is an array of all of the dns master ips
  # real_master_ip_array is the same array, excluding the host's ip address
  # slave_ip_array is an array of all of the slave (net02) ip addresses
  # We sort/concat the real_master_ip_array and slave_ip_array to create an array that we pass
  # to "notifyalso" in bind.  Basically giving us the line:
  # 'also-notify { 10.0.22.11; 10.28.22.11; 10.28.22.12; 10.32.22.9; 10.32.22.10; 10.48.22.13; 10.48.22.14; };'
  #
  # slave_array is used later on to iterate over every other zone besides our current zone to set up the slave definitions
  # for master hosts
  $dns_array = hiera('profile::dns::zones')
  $master_ip_array = $dns_array.map |$zone| { $zone[1]['zonemaster_ip'] }
  $real_master_ip_array = $master_ip_array - $facts['networking']['ip']
  $slave_ip_array = $dns_array.map |$zone| { $zone[1]['zoneslave_ip'] }
  $notify_array = sort(concat($real_master_ip_array, $slave_ip_array))
  $slave_array = $dns_array - $location

  # Determine if this host is a master or slave
  if member($master_ip_array, $facts['networking']['ip']) {
    $dns_type = 'master'
  } else {
    $dns_type = 'slave'
  }

  Bind::Zone {
    allow_update => 'key "dhcp_updater"',
    require      => Bind::Key['dhcp_updater'],
  }

  # ----------
  # Create Zones
  # ----------
  # Create zone records for all zones in our current location
  # eg - {pdx => {zonemaster_ip => 10.0.22.10, zoneslave_ip => 10.0.22.11, zones => [puppetlabs.lan, puppetlabs.net, corp.puppetlabs.net,
  # oob.puppetlabs.net, phones.puppetlabs.net, 0.10.in-addr.arpa., 168.192.in-addr.arpa.]}
  if $dns_type == 'master' {
    bind::zone { $dns_array[$location][zones]:
      type       => 'master',
      notifyalso => $notify_array,
    }
    # Slave_array is dns_array minus our current zone, which is already configured as master
    $slave_array.each |$zone| {
      bind::zone { $zone[1]['zones']:
        type    => 'slave',
        masters => $zone[1]['zonemaster_ip'],
      }
    }
  } else {
    $dns_array.each |$zone| {
      bind::zone { $zone[1]['zones']:
        type    => 'slave',
        masters => $zone[1]['zonemaster_ip'],
      }
    }
  }
  # Add forward zones, if we have any
  $forward_zones.each |$zone| {
    bind::zone { $zone[0]:
      type    => 'forward',
      masters => $zone[1]['zone_masters'],
    }
  }
}
