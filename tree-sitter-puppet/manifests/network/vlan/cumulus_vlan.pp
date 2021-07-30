define profile::network::vlan::cumulus_vlan (
  $vid,
  $tagged_ports        = [],
  $native_ports        = [],
  $uplink_ports        = [],
  $ipv4                = undef,
  $ipv6                = undef,
  $vrr_ip              = undef,
  $vrr_mac             = undef,
  $mstpctl_treeprio    = 61440,
  $alias_name          = "${title} VLAN ID ${vid}",
  $stp                 = true,
  $bpdu_filter_enable  = true,
){
  file {"/etc/network/interfaces.d/${title}":
    ensure  => undef,
  }

  $tagged_ifs = $tagged_ports.map |$if| { "${if}.${vid}" }
  $uplink_ifs = $uplink_ports.map |$if| { "${if}.${vid}" }

  if $bpdu_filter_enable {
    $filtered_ports = $native_ports + $tagged_ifs
  } else {
    $filtered_ports = []
  }

  cumulus_bridge { $title:
    ports                  =>  $native_ports + $tagged_ifs + $uplink_ifs,
    ipv4                   =>  $ipv4,
    ipv6                   =>  $ipv6,
    virtual_ip             =>  $vrr_ip,
    virtual_mac            =>  $vrr_mac,
    alias_name             =>  $alias_name,
    mstpctl_treeprio       =>  $mstpctl_treeprio,
    mstpctl_portbpdufilter =>  $filtered_ports,
    stp                    =>  $stp,
    notify                 =>  Exec['reload_config'],
  }
}

