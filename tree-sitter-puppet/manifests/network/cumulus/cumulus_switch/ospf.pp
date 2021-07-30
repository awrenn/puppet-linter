class profile::network::cumulus::cumulus_switch::ospf (
  $config  = {},
){
  # Quagga OSPF Configuration
  if $config['ospf_router_id'] {
    if $config['other_vlans'] {
      $ospf_vlan_interfaces = $config['other_vlans'].reduce({}) |$memo, $value| {
        $vlan_name = $value[0]
        $vlan = $value[1]

        if $vlan['ospf_area'] {
          $area = $vlan['ospf_area']
        } else {
          $area = '0.0.0.0'
        }

        unless $vlan['ospf_active'] {
          $passive = true
        } else {
          $passive = false
        }

        $r_hash = { $vlan_name => { 'area' => $area, 'passive' => $passive } } + $memo

        $r_hash
      }
    } else {
      $ospf_vlan_interfaces = {}
    }

    if $config['other_ports'] {
      $ospf_port_interfaces = $config['other_ports'].reduce({}) |$memo, $value| {
        $port_name = $value[0]
        $port = $value[1]

        if $port['ospf_area'] {
          $area = $port['ospf_area']
        } else {
          $area = '0.0.0.0'
        }

        unless $port['ospf_active'] {
          $passive = true
        } else {
          $passive = false
        }

        $r_hash = { $port_name => { 'area' => $area, 'passive' => $passive } } + $memo

        $r_hash
      }
    } else {
      $ospf_port_interfaces = {}
    }

    if ($config['wifi']) or ($config['user']) {
      $ospf_default_interfaces = {
        'corp'    => {
          'area'    => '0.0.0.0',
          'passive' => true,
        },
        'phones'  => {
          'area'    => '0.0.0.0',
          'passive' => true,
        },
        'w_mup'   => {
          'area'    => '0.0.0.0',
          'passive' => true,
        },
        'w_mgmt'  => {
          'area'    => '0.0.0.0',
          'passive' => true,
        },
        'w_guest' => {
          'area'    => '0.0.0.0',
          'passive' => true,
        },
      }
    } else {
      $ospf_default_interfaces = {}
    }

    if $config['ospf_ref_bw'] {
      $ospf_ref_bw = $config['ospf_ref_bw']
    } else {
      $ospf_ref_bw = '100'
    }

    file {'/etc/quagga/Quagga.conf':
      ensure => absent,
      before => Class['quagga'],
    }

    class {'quagga':
      hostname       => $facts['networking']['hostname'],
      router_id      => $config['ospf_router_id'],
      ospf_ref_bw    => $ospf_ref_bw,
      interfaces     => $ospf_vlan_interfaces + $ospf_port_interfaces + $ospf_default_interfaces,
      zebra          => true,
      ospfd          => true,
      ospf_areas     => [],
      redistribute   => [],
      networks       => [],
      service_enable => true,
    }

    # We need to give time to let OSPF converge
    exec {'OSPF Converge Delay':
      path        => '/bin',
      command     => 'sleep 5',
      subscribe   => Service['quagga'],
      refreshonly => true,
    }
  }
}
