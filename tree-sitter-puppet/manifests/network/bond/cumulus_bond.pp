define profile::network::bond::cumulus_bond (
  $slaves,
  $lacp_bypass_allow  =  1,
  $clag_id            =  undef,
  $mtu                =  undef,
){
  cumulus_bond { $title:
    slaves            =>  $slaves,
    lacp_bypass_allow =>  $lacp_bypass_allow,
    clag_id           =>  $clag_id,
    mtu               =>  $mtu,
  }

  file {"/etc/network/interfaces.d/${name}":
    ensure  => undef,
  }
}
