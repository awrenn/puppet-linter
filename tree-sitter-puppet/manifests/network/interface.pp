# site/profile/manifests/network/interface.pp
class profile::network::interface {
  # Configures Cumulus L3 interfaces.
  if $facts['os']['name'] == 'CumulusLinux' {
    include profile::network::interface::cumulus
  }
}
