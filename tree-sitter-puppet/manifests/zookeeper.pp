# Class: profile::zookeeper
#
class profile::zookeeper(
  $cluster_name               = $profile::zookeeper::common::cluster_name,
  $max_allowed_connections    = undef,
  $client_ip                  = undef,
  Optional[Tuple] $zookeepers = undef,
) inherits profile::zookeeper::common {
  include profile::zookeeper::common
  include profile::server::params

  if $profile::server::params::monitoring == true {
    include profile::zookeeper::monitor
  }

  if $profile::server::params::metrics == true {
    include profile::zookeeper::metrics
  }

  if $profile::server::params::fw {
    include profile::zookeeper::firewall
  }

  case $facts['os']['family'] {
    'Debian' : {
      $packages        = ['zookeeper']
      $repo_source     = "http://archive.cloudera.com/cdh5/debian/${facts['os']['distro']['codename']}/${facts['os']['architecture']}/cdh"
      $service_name    = 'zookeeper-server'

      apt::source { 'cloudera':
        location => $repo_source,
        release  => "${facts['os']['distro']['codename']}-cdh5",
        repos    => 'contrib',
        key      => {
          'id'     => '02A818DD',
          'source' => "${repo_source}/archive.key",
        },
      }
    }
    'RedHat' : {
      $packages        = ['zookeeper','zookeeper-server']
      $service_name    = 'zookeeper-server'

      yumrepo { 'cloudera':
        descr    => 'cloudera',
        enabled  => 1,
        baseurl  => 'http://archive.cloudera.com/cdh5/redhat/7/x86_64/cdh/5',
        gpgcheck => 1,
        gpgkey   => 'http://archive.cloudera.com/cdh5/redhat/7/x86_64/cdh/RPM-GPG-KEY-cloudera',
      }
    }
    default: {}
  }

  $id      = hiera('profile::zookeeper::id', $facts['classification']['number_string'])
  $servers = sort(pick($zookeepers, $profile::zookeeper::common::pdbquery_zookeepers.map |$zk| { $zk }))
  include java

  file { '/root/servers':
    ensure  => present,
    content => $servers,
  }

  meta_motd::register { 'Apache ZooKeeper (profile::zookeeper)': }

  if $servers != undef {
    class { '::zookeeper':
      id                      => $id,
      initialize_datastore    => true,
      packages                => $packages,
      servers                 => $servers,
      service_name            => $service_name,
      snap_retain_count       => 10,
      purge_interval          => 12,
      client_ip               => $client_ip,
      max_allowed_connections => $max_allowed_connections,
      require                 => Class['java'],
    }
  } else {
    notify { 'There are no nodes in the specified zookeeper cluster. This run will not set up the zookeeper class, but will register the profile for the node.': }
  }
}
