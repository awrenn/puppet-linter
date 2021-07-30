# Install Bind and monitoring for DNS secondary hosts. This is for secondary
# only hosts that are not using dns::server.
class profile::dns::secondary (
  $forward_zones,
){
  include profile::dns::common
  if $::profile::server::params::monitoring {
    include profile::dns::monitor
  }

  $dns_array = hiera('profile::dns::zones')

  $dns_array.each |$zone| {
    bind::zone { $zone[1]['zones']:
      type    => 'slave',
      masters => $zone[1]['zonemaster_ip'],
    }
  }

  # Add forward zones, if we have any
  $forward_zones.each |$zone| {
    bind::zone { $zone[0]:
      type    => 'forward',
      masters => $zone[1]['zone_masters'],
    }
  }
}
