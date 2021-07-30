# http://docs.platform9.com/support/neutron-prerequisites-centos-linuxkvm-overlays-vxlangre-vlans/
#
# VLAN will be configured on `bond0` based on `$vlans`. The `first_ip` parameter
# is the IP address of the first compute node (based on the number in the
# hostname). Each compute node gets a sequential IP.
#
# For example, if `first_ip => '10.0.0.1'` then compute node 1 gets IP
# `10.0.0.1`, compute node 2 gets `10.0.0.2`, etc.
class profile::p9openstack::networking (
  Hash[Integer[0, 4095], Struct[{
    first_ip => Stdlib::IP::Address::V4::Nosubnet,
    netmask  => Stdlib::IP::Address::V4::Nosubnet,
    mtu      => Integer[68, 9000],
  }]] $vlans = {}
) {
  kmod::load { 'bridge': }
  kmod::load { '8021q': }
  kmod::load { 'bonding': }
  kmod::load { 'tun': }

  # Needed for net.bridge.bridge-nf-call-iptables
  kmod::load { 'br_netfilter': }

  sysctl::value {
    default:
      notify => Service['pf9-hostagent'],
    ;
    'net.ipv4.conf.all.rp_filter':        value => '0';
    'net.ipv4.conf.default.rp_filter':    value => '0';
    'net.bridge.bridge-nf-call-iptables': value => '1';
    'net.ipv4.ip_forward':                value => '1';
    'net.ipv4.tcp_mtu_probing':           value => '2';
    # INFC-17324: we talk to lots of IPs; adjust the ARP table GC thresholds
    'net.ipv4.neigh.default.gc_thresh1':  value => '4096';
    'net.ipv4.neigh.default.gc_thresh2':  value => '8192';
    'net.ipv4.neigh.default.gc_thresh3':  value => '16384';
    # We probably don't need ipv6
    'net.ipv6.neigh.default.gc_thresh1':  value => '4096';
    'net.ipv6.neigh.default.gc_thresh2':  value => '8192';
    'net.ipv6.neigh.default.gc_thresh3':  value => '16384';
    # Prevent "dnsmasq: failed to create inotify: Too many open files"
    'fs.inotify.max_user_instances':      value => '4096'; # arbitrary
  }

  Kmod::Load <| |> -> Sysctl::Value <| |>

  file {
    default:
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0444',
      notify => Service['pf9-hostagent'],
    ;
    '/etc/systemd/system/pf9-hostagent.d':
      ensure => directory,
      mode   => '0755',
    ;
    '/etc/systemd/system/pf9-hostagent.d/override.conf':
      source => 'puppet:///modules/profile/p9openstack/systemd-pf9-hostagent-override.conf',
    ;
    '/etc/security/limits.d/50-puppet-pf9.conf':
      source => 'puppet:///modules/profile/p9openstack/limits.d/50-puppet-pf9.conf',
    ;
  }

  network_config { 'bond0':
    ensure  => present,
    method  => none,
    mtu     => '9000',
    options => {
      'BONDING_MASTER' => 'yes',
      'BONDING_OPTS'   => 'mode=4',
    },
  }

  case $facts['dmi']['product']['name'] {
    'PowerEdge R640': {
      $bond_interfaces = ['em1', 'em2']
    }
    default: {
      $bond_interfaces = ['enp7s0', 'enp12s0']
    }
  }

  network_config { $bond_interfaces:
    ensure  => present,
    method  => none,
    mtu     => '9000',
    options => {
      'MASTER' => 'bond0',
      'SLAVE'  => 'yes',
    },
  }

  $vlans.each |$vlan, $info| {
    # See the class comments for an explanation of what this is supposed to do.
    $octets = $info['first_ip'].split('[.]') # Split uses a regex
    $prefix = $octets[0,3].join('.') # The first three octets
    $last_octet = Integer($octets[3]) + $facts['classification']['number'] - 1

    network_config { "bond0.${vlan}":
      ensure    => present,
      ipaddress => "${prefix}.${last_octet}",
      netmask   => $info['netmask'],
      method    => none,
      mode      => vlan,
      mtu       => String($info['mtu']), # sigh
    }
  }

  package { 'platform9-neutron-repo-1-0':
    provider => rpm,
    source   => 'https://s3-us-west-1.amazonaws.com/platform9-neutron/noarch/platform9-neutron-repo-1-0.noarch.rpm',
  }

  package { 'openvswitch':
    require => Package['platform9-neutron-repo-1-0'],
  }

  service { 'openvswitch':
    ensure    => running,
    enable    => true,
    subscribe => Package['openvswitch'],
  }

  # The openstack-vswitch module overwrites the bond0 configuration, so we
  # configure it with exec.
  exec {
    default:
      path    => '/usr/bin:/usr/sbin:/bin:/sbin',
      user    => 'root',
      require => [
        Service['openvswitch'],
        Network_config['bond0'],
      ],
    ;
    'ovs-vsctl add-br br-vlan':
      unless => 'ovs-vsctl br-exists br-vlan',
    ;
    'ovs-vsctl add-port br-vlan bond0':
      unless  => 'ovs-vsctl iface-to-br bond0',
      require => Exec['ovs-vsctl add-br br-vlan'],
      notify  => Service['pf9-hostagent'],
    ;
  }
}
