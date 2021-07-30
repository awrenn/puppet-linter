##
#
class profile::mesos::common(
  String[1] $mesos_version = 'present'
  ){

  include profile::zookeeper::common
  $zookeepers = hiera('profile::mesos::common::zookeepers', join([ 'zk://', join($::profile::zookeeper::common::pdbquery_zookeepers, ':2181,'),':2181/mesos']))

  if $zookeepers != [] {
    class { '::mesos':
      repo           => 'mesosphere',
      ensure         => $mesos_version,
      listen_address => $facts['networking']['ip'],
      zookeeper      => $zookeepers,
    }
  }
  else {
    notify { 'Could not fine zookeeper nodes for Profile::Mesos::Common': }
  }
}
