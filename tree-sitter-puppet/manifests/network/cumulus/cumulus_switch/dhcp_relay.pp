class profile::network::cumulus::cumulus_switch::dhcp_relay (
  $config  = {},
){
  # DHCP Relay Config
  if $config['dhcp_servers'] {
    if $config['other_vlans'] {
      $other_vlan_dhcp_enable = $config['other_vlans'].map |String $name, Hash $vlan| {
        if $vlan['dhcp'] == true {
          "-i ${name}"
        } else {
          ''
        }
      }
    } else {
      $other_vlan_dhcp_enable = []
    }

    if $config['other_ports'] {
      $other_ports_dhcp_enable = $config['other_ports'].map |String $name, Hash $port| {
        if $port['dhcp'] == true {
          "-i ${name}"
        } else {
          ''
        }
      }
    } else {
      $other_ports_dhcp_enable = []
    }

    $dhcp_vlans = $other_vlan_dhcp_enable + $other_ports_dhcp_enable + ['-i corp', '-i phones', '-i w_mgmt', '-i w_mup']

    file_line { 'dhcp vlans':
      ensure =>  present,
      path   =>  '/etc/default/isc-dhcp-relay',
      line   =>  "INTF_CMD=\"${join($dhcp_vlans, ' ')}\"",
      match  =>  '^INTF_CMD',
      notify =>  Service['dhcrelay'],
    }

    file_line { 'dhcp servers':
      ensure =>  present,
      path   =>  '/etc/default/isc-dhcp-relay',
      line   =>  "SERVERS=\"${join($config['dhcp_servers'], ' ')}\"",
      match  =>  '^SERVERS',
      notify =>  Service['dhcrelay'],
    }

    $dhcrelay_service = 'running'
    $dhcrelay_enable = true
  } else {
    $dhcrelay_service = 'stopped'
    $dhcrelay_enable = false
  }

  service {'dhcrelay':
    ensure => $dhcrelay_service,
    enable => $dhcrelay_enable,
  }
}
