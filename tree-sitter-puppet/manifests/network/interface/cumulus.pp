# site/profile/manifests/network/interface/cumulus.pp
class profile::network::interface::cumulus {

  # Parse interfaces in hiera.
  $interfaces = hiera('profile::network::interfaces', {})

  $interfaces.each |$interface, $data| {
    cumulus_interface { "${interface}":
      addr_method => $data['addr_method'],
      alias_name  => $data['desc'],
      ipv4        => $data['ipv4'],
      speed       => $data['speed'],
      notify      => Exec['ifreload-all'],
    }
  }
}
