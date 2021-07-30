# Enable live migration
#
# https://docs.platform9.com/support/live-migration-with-platform9-managed-openstack/
class profile::p9openstack::migration::live {
  file {
    default:
      ensure => file,
      owner  => 'root',
      group  => '0',
      mode   => '0444',
      notify => Service['libvirtd'],
    ;
    '/etc/libvirt':
      ensure => directory,
      mode   => '0600',
    ;
    '/etc/libvirt/libvirtd.conf':
      source => 'puppet:///modules/profile/p9openstack/libvirtd.conf',
    ;
    '/etc/sysconfig/libvirtd':
      source => 'puppet:///modules/profile/p9openstack/libvirtd-sysconfig',
    ;
  }

  package { 'sysfsutils': }

  service { 'libvirtd':
    ensure  => running,
    enable  => true,
    require => Service['pf9-ostackhost'],
  }
}
