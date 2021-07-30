# site/profile/manifests/network/vlan.pp
class profile::network::vlan {
  if $facts['os']['name'] == 'CumulusLinux' {
    include profile::network::vlan::cumulus
  }
  else {
    notify { "Unsupported operatingsystem ${facts['os']['name']}": }
  }
}
