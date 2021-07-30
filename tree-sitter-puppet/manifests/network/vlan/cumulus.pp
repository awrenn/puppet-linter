# site/profile/manifests/network/vlan/cumulus.pp
class profile::network::vlan::cumulus {
  $vlans = hiera('profile::network::vlans', {})

  $vlans.each |$vlan, $data| {
    profile::network::vlan::cumulus_vlan {"${vlan}":
      vid              => $data['vids'],
      native_ports     => $data['ports'],
      mstpctl_treeprio => $data['mstpctl_treeprio'],
      alias_name       => $data['desc'],
      stp              => $data['stp'],
    }
  }
}
