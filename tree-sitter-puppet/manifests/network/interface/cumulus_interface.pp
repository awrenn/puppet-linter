define profile::network::interface::cumulus_interface (
  $ipv4             = [],
  $addr_method      = undef,
  $clagd_enable     = undef,
  $clagd_priority   = undef,
  $clagd_peer_ip    = undef,
  $clagd_backup_ip  = undef,
  $clagd_sys_mac    = undef,
  $speed            = undef,
  $autoneg          = undef,
  $mtu              = undef,
){
  file {"/etc/network/interfaces.d/${name}":
    ensure  => undef,
  }

  cumulus_interface { $title:
    ipv4            =>  $ipv4,
    addr_method     =>  $addr_method,
    clagd_enable    =>  $clagd_enable,
    clagd_priority  =>  $clagd_priority,
    clagd_peer_ip   =>  $clagd_peer_ip,
    clagd_backup_ip =>  $clagd_backup_ip,
    clagd_sys_mac   =>  $clagd_sys_mac,
    speed           =>  $speed,
    autoneg         =>  $autoneg,
    mtu             =>  $mtu,
    notify          =>  Exec['reload_config'],
  }
}
