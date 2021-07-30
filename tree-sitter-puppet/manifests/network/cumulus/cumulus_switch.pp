class profile::network::cumulus::cumulus_switch (
  $config  = hiera('profile::network::cumulus::cumulus_switch'),
){
  $default_vids = { 'corp'         => 8,
                    'it_printers'  => 29,
                    'it_rvlan'     => 30,
                    'ops'          => 22,
                    'phones'       => 33,
                    'routers'      => 66,
                    'testnet'      => 100,
                    'workplace'    => 34,
                    'w_guest'      => 12,
                    'w_mgmt'       => 23,
                    'w_mup'        => 24,
                  }

  class {'::profile::network::cumulus::cumulus_switch::l2_l3':
    config       =>  $config,
    default_vids =>  $default_vids,
  }

  class {'::profile::network::cumulus::cumulus_switch::dhcp_relay':
    config  =>  $config,
  }

  class {'::profile::network::cumulus::cumulus_switch::ospf':
    config  =>  $config,
  }

  class {'::profile::network::cumulus::cumulus_switch::snmp':
    config  =>  $config,
  }
}
