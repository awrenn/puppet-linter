# A compute node
#
# All compute nodes should be set up in the Platform9 UI as having an image
# store. Use the default path (/var/opt/pf9/imagelibrary/data).
#
# If $nfs_path is on a Tintri, you must first mount the Tintri over NFS
# and then mkdir the paths you want. For example:
#
#     # mount -t nfs -o vers=3 tintri-data-foo.bar.net:/tintri /mnt
#     # mkdir -p /mnt/p9openstack-prod/{images,cinder}
#     # umount /mnt
class profile::p9openstack::compute (
  String[1] $nfs_path,
  String[1] $images_nfs_path   = "${nfs_path}/images",
  String[1] $nova_debug        = 'False',
  String[1] $p9openstack_proxy = 'p9openstack-proxy-opdx-prod-1.ops.puppetlabs.net',
  Boolean   $cinder            = false,
) {
  profile_metadata::service { $title:
    human_name => 'Platform9 OpenStack compute',
    team       => dio,
  }

  include profile::p9openstack::migration::cold
  include profile::p9openstack::migration::live

  if $cinder {
    include profile::p9openstack::cinder
  }

  file {
    default:
      ensure => directory,
      owner  => 'pf9',
      group  => 'pf9group',
      mode   => '0755',
    ;
    '/etc/glance': ;
    '/etc/glance/nfs_shares':
      ensure  => file,
      mode    => '0444',
      content => "${nfs_path}/images\n",
    ;
    '/var/opt/pf9/imagelibrary': ;
    '/var/opt/pf9/imagelibrary/data': ;
    '/opt/pf9/data': ;
    '/opt/pf9/data/instances': ;
    '/opt/pf9/etc/nova': ;
    '/opt/pf9/etc/nova/conf.d': ;
    '/opt/pf9/etc/nova/conf.d/nova-tintri.conf':
      ensure => file,
      mode   => '0440',
      source => 'puppet:///modules/profile/p9openstack/nova-tintri.conf',
      before => Service['pf9-hostagent'],
      notify => Service['pf9-ostackhost'],
    ;
  }

  ### Workaround provided by Platform9. We need a manually built OVMF package for UEFI boots to work.
  ### If we ever move to CentOS 8 we could remove this and instead use the edk2 package
  ### https://support.platform9.com/hc/en-us/requests/1333700
  file {
    default:
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
    ;
    '/usr/share/OVMF':
      ensure => directory,
      mode   => '0755'
    ;
    '/usr/share/OVMF/OVMF_CODE.secboot.fd':
      source => 'https://artifactory.delivery.puppetlabs.net/artifactory/generic__local/infracore/platform9/OVMF_CODE.secboot.fd',
    ;
    '/usr/share/OVMF/OVMF_CODE.fd':
      ensure => link,
      target => '/usr/share/OVMF/OVMF_CODE.secboot.fd',
    ;
    '/usr/share/OVMF/OVMF_VARS.secboot.fd':
      source => 'https://artifactory.delivery.puppetlabs.net/artifactory/generic__local/infracore/platform9/OVMF_VARS.secboot.fd',
    ;
    '/usr/share/OVMF/OVMF_VARS.fd':
      source => 'https://artifactory.delivery.puppetlabs.net/artifactory/generic__local/infracore/platform9/OVMF_VARS.fd',
    ;
  }

  mount { '/var/opt/pf9/imagelibrary/data':
    ensure  => mounted,
    fstype  => 'nfs',
    options => 'vers=3,lookupcache=pos',
    device  => $images_nfs_path,
    require => File['/var/opt/pf9/imagelibrary/data'],
    notify  => Service['pf9-hostagent'],
  }

  service { 'pf9-ostackhost':
    ensure  => running,
    enable  => true,
    require => Service['pf9-hostagent'],
  }

  service { 'pf9-novncproxy':
    ensure  => running,
    enable  => true,
    require => Service['pf9-hostagent'],
  }

  # enable https proxy for platform 9
  file { '/opt/pf9/etc/nova/conf.d/nova_override.conf':
    ensure  => present,
    content => @("END"),
            [DEFAULT]
            novncproxy_base_url = http://${p9openstack_proxy}/${fqdn}/vnc_auto.html
            block_device_allocate_retries = 120
            block_device_allocate_retries_interval = 6
            vif_plugging_timeout = 600
            debug = ${nova_debug}
            [libvirt]
            cpu_mode=custom
            cpu_model=Haswell-noTSX-IBRS
            live_migration_permit_auto_converge = True
            | END
    before  => Service['pf9-hostagent'],
    notify  => [Service['pf9-ostackhost'], Service['pf9-novncproxy']],
  }

}
