# Profile for common DHCP configuration
#
class profile::dhcp::common (
  $nameservers        = lookup('profile::network::nameservers'),
  $ntpservers         = lookup('profile::dhcp::ntpservers'),
  $pxeserver          = lookup('profile::network::pxeserver'),
  $pxefilename        = lookup('profile::network::pxefilename'),
  $interfaces         = lookup('profile::dhcp::interfaces'),
  $ddnsdomains        = lookup('profile::dhcp::ddnsdomains'),
  $dnskeyname         = lookup('profile::dns::ddnskeyname'),
  $primaryserver      = lookup('profile::dhcp::primaryserver'),
  $secondaryserver    = lookup('profile::dhcp::secondaryserver'),
  $primaryserver_ip   = lookup('profile::dhcp::primaryserver_ip'),
  $secondaryserver_ip = lookup('profile::dhcp::secondaryserver_ip'),
  $pools              = lookup('profile::dhcp::pools'),
) {
  include profile::server::params
  include profile::dhcp::metrics
  if ($::profile::server::params::monitoring == true) { include profile::dhcp::monitor }

  class { 'dhcp':
    dnsdomain          => $ddnsdomains,
    nameservers        => $nameservers,
    ntpservers         => $ntpservers,
    interfaces         => $interfaces,
    dnsupdatekey       => "/etc/bind/keys.d/${dnskeyname}",
    require            => Bind::Key[$dnskeyname],
    pxeserver          => $pxeserver,
    pxefilename        => $pxefilename,
    default_lease_time => 86400,
  }

  # ----------
  # Begin Pools
  # ----------
  Dhcp::Pool { failover => 'dhcp-failover' }

  create_resources('dhcp::pool', $pools)

  # ----------
  # Failover
  # ----------
  if $facts['networking']['fqdn'] == $primaryserver {
    class { 'dhcp::failover':
      peer_address => $secondaryserver_ip,
      load_split   => '255', # ITOPS-1920 Serve all clients off the primary server
    }
  } else {
    class { 'dhcp::failover':
      role         => 'secondary',
      peer_address => $primaryserver_ip,
    }
  }
}
