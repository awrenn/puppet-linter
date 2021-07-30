##
#
class profile::mesos::dns (
  Optional[String] $domain           = undef,
  Optional[String] $soamname         = undef,
  Optional[String] $soarname         = undef,
  Optional[String] $version          = undef,
  Optional[Array[String]] $resolvers = undef,
  Optional[Array[String]] $ipsources = undef,
) {

  $zookeepers = join([ 'zk://', join(hiera('profile::mesos::common::zookeepers'), ','), ':2181/mesos'])

  if $zookeepers != [] {
    class { '::mesosdns':
      mesos_zk       => $zookeepers,
      domain         => $domain,
      ip_sources     => $ipsources,
      resolvers      => $resolvers,
      soa_mname      => $soamname,
      soa_rname      => $soarname,
      service_status => 'unmanaged',
      version        => $version,
    }
  }
  else {
    notify { 'Could not find zookeeper nodes for Profile::Mesos::Common': }
  }
}
