class profile::network::cumulus::cumulus_switch::l2_l3 (
  $config        =  {},
  $default_vids  =  {},
){
  file_line {'source_interfaces.d':
    ensure => present,
    path   => '/etc/network/interfaces',
    line   => 'source /etc/network/interfaces.d/*',
  }

  file {'/etc/network/interfaces.d':
    ensure  => directory,
    recurse => true,
    purge   => true,
    notify  => Exec['reload_config'],
  }

  exec {'reload_config':
    path        => '/sbin',
    command     => '/sbin/ifreload -a',
    refreshonly => true,
  }

  # 40G Port Splitting
  if $config['40g_split'] {
    cumulus_ports { 'speeds':
      speed_4_by_10g => $config['40g_split'],
    }
  }

  # Uplink port configuration
  if $config['uplinks'] {
    $config_uplink_ports = $config['uplinks'].map |$type, $value| {
      case $type {
        'single_ports': {
          $value
        }
        'groups': {
          $value.map |$group_name, $values| {
            profile::network::bond::cumulus_bond { "${group_name}":
              slaves  =>  $values['ports'],
              clag_id =>  $values['clag_id'],
              mtu     =>  $values['mtu'],
            }
            $group_name
          }.flatten
        }
        default: {
          fail 'Unrecognised value in config hash.'
        }
      }
    }.flatten
  } else {
    $config_uplink_ports = []
  }

  # MLAG Peerlink configuration
  if $config.dig('uplinks','groups', 'peerlink') {
    $values = $config['uplinks']['groups']['peerlink']
    profile::network::interface::cumulus_interface {'peerlink.4000':
      ipv4            =>  $values['clag_ip'],
      clagd_enable    =>  true,
      clagd_priority  =>  $values['clag_prio'],
      clagd_peer_ip   =>  $values['clag_peer_ip'],
      clagd_backup_ip =>  $values['clag_backup_ip'],
      clagd_sys_mac   =>  $values['clag_mac'],
    }

    profile::network::vlan::cumulus_vlan {'mlag_native':
      vid                =>  'none',
      tagged_ports       =>  [],
      native_ports       =>  $config_uplink_ports,
      mstpctl_treeprio   =>  $config['stp_prio'],
      bpdu_filter_enable =>  false,
    }
  }

  # WiFi AP Array building and bond configuration
  if $config.dig('wifi','aps') {
    $wifi_ports = $config['wifi']['aps'].map |String $name, Hash $ap| {
      profile::network::bond::cumulus_bond { "${name}":
        slaves  =>  $ap['ports'],
      }
      $name
    }.flatten
  } else {
    $wifi_ports = []
  }

  $config.each |$key, $value| {
    case $key {
      'other_ports': {
        $value.each |String $name, Hash $port| {
          if $port['sfp'] {
            $port_speed = $port['sfp']
            $autoneg = 'off'
          } else {
            $port_speed = undef
            $autoneg = undef
          }

          profile::network::interface::cumulus_interface {"${name}":
            ipv4        =>  $port['ipv4'],
            addr_method =>  $port['type'],
            speed       =>  $port_speed,
            autoneg     =>  $autoneg,
            mtu         =>  $port['mtu'],
          }
        }
      }

      'other_vlans': {
        $value.each |String $name, Hash $vlan| {
          if !$vlan['vid'] {
            if !$default_vids[$name] {
              fail "You must specify a vid for VLAN ${name}, as it does not have a default vid available."
            } else {
              $vid = $default_vids[$name]
            }
          } else {
            $vid = $vlan['vid']
          }


          $vlan_tagged_ports =  $vlan['tagged_ports'] ? {
            undef    => [],
            default  => $vlan['tagged_ports'],
          }

          $vlan_native_ports =  $vlan['ports'] ? {
            undef    => [],
            default  => $vlan['ports'],
          }

          if $vlan['uplink'] != undef and $vlan['uplink'] == false {
            $vlan_uplink_ports = []
          } else {
            $vlan_uplink_ports = $config_uplink_ports
          }

          profile::network::vlan::cumulus_vlan {"${name}":
            vid              =>  $vid,
            tagged_ports     =>  $vlan_tagged_ports,
            native_ports     =>  $vlan_native_ports,
            uplink_ports     =>  $vlan_uplink_ports,
            ipv4             =>  $vlan['ipv4'],
            vrr_ip           =>  $vlan['vrr_ip'],
            vrr_mac          =>  $vlan['vrr_mac'],
            mstpctl_treeprio =>  $config['stp_prio'],
          }
        }
      }

      'user': {
        profile::network::vlan::cumulus_vlan {'corp':
          vid              =>  $default_vids['corp'],
          native_ports     =>  $value['ports'],
          tagged_ports     =>  [],
          uplink_ports     =>  $config_uplink_ports,
          ipv4             =>  $value['corp_ip'],
          vrr_ip           =>  $value['corp_vrr_ip'],
          vrr_mac          =>  $value['corp_vrr_mac'],
          mstpctl_treeprio =>  $config['stp_prio'],
        }

        profile::network::vlan::cumulus_vlan {'it_printers':
          vid              =>  $default_vids['it_printers'],
          native_ports     =>  [],
          tagged_ports     =>  $value['ports'],
          uplink_ports     =>  $config_uplink_ports,
          ipv4             =>  $value['it_printers_ip'],
          vrr_ip           =>  $value['it_printers_vrr_ip'],
          vrr_mac          =>  $value['it_printers_vrr_mac'],
          mstpctl_treeprio =>  $config['stp_prio'],
        }

        profile::network::vlan::cumulus_vlan {'it_rvlan':
          vid              =>  $default_vids['it_rvlan'],
          native_ports     =>  [],
          tagged_ports     =>  $value['ports'] + $wifi_ports,
          uplink_ports     =>  $config_uplink_ports,
          ipv4             =>  $value['it_rvlan_ip'],
          vrr_ip           =>  $value['it_rvlan_vrr_ip'],
          vrr_mac          =>  $value['it_rvlan_vrr_mac'],
          mstpctl_treeprio =>  $config['stp_prio'],
        }

        profile::network::vlan::cumulus_vlan {'phones':
          vid              =>  $default_vids['phones'],
          native_ports     =>  $value['phones_native_ports'],
          tagged_ports     =>  $value['ports'] + $wifi_ports,
          uplink_ports     =>  $config_uplink_ports,
          ipv4             =>  $value['phones_ip'],
          vrr_ip           =>  $value['phones_vrr_ip'],
          vrr_mac          =>  $value['phones_vrr_mac'],
          mstpctl_treeprio =>  $config['stp_prio'],
        }
      }

      'wifi': {
        profile::network::vlan::cumulus_vlan {'w_mgmt':
          vid              =>  $default_vids['w_mgmt'],
          native_ports     =>  $wifi_ports,
          tagged_ports     =>  [],
          uplink_ports     =>  $config_uplink_ports,
          ipv4             =>  $value['mgmt_ip'],
          vrr_ip           =>  $value['mgmt_vrr_ip'],
          vrr_mac          =>  $value['mgmt_vrr_mac'],
          mstpctl_treeprio =>  $config['stp_prio'],
        }

        profile::network::vlan::cumulus_vlan {'w_mup':
          vid              =>  $default_vids['w_mup'],
          tagged_ports     =>  $wifi_ports,
          uplink_ports     =>  $config_uplink_ports,
          ipv4             =>  $value['muppets_ip'],
          vrr_ip           =>  $value['muppets_vrr_ip'],
          vrr_mac          =>  $value['muppets_vrr_mac'],
          mstpctl_treeprio =>  $config['stp_prio'],
        }

        $guest_tagged_ports = delete_undef_values($wifi_ports + $value.dig('guest_network', 'uplink_ports'))
        $guest_native_ports = $value.dig('guest_network', 'native_ports')
        $guest_ipv4 = $value.dig('guest_network', 'guest_ip')
        $guest_vrr_ip = $value.dig('guest_network', 'guest_vrr_ip')
        $guest_vrr_mac = $value.dig('guest_network', 'guest_vrr_mac')

        profile::network::vlan::cumulus_vlan {'w_guest':
          vid              =>  $default_vids['w_guest'],
          tagged_ports     =>  $guest_tagged_ports,
          native_ports     =>  $guest_native_ports,
          uplink_ports     =>  $config_uplink_ports,
          ipv4             =>  $guest_ipv4,
          vrr_ip           =>  $guest_vrr_ip,
          vrr_mac          =>  $guest_vrr_mac,
          mstpctl_treeprio =>  $config['stp_prio'],
        }
      }
    }
  }
}
