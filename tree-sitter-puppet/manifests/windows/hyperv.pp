class profile::windows::hyperv {

  windowsfeature { 'Hyper-V':
    ensure => present,
  }

  reboot {'after_Hyper_V':
    when      => pending,
    subscribe => Windowsfeature['Hyper-V'],
  }

  profile::network::windows_nic_team { 'nic_team1-HyperV':
    nic_name    => 'Team1 - HyperV',
    teammembers => ['NIC1', 'NIC2'],
  }

  profile::network::windows_nic_team { 'nic_team2-Vlan22':
    nic_name    => 'Team2 - VLAN 22',
    teammembers => ['NIC3', 'NIC4'],
    ipaddress   => ['10.32.22.11/23'],
    gw_address  => '10.32.22.1',
  }
}
