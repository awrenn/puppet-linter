# Allow multipathing for third party devices
class profile::os::solaris::scsi_vhci {

  file { '/etc/driver/drv/scsi_vhci.conf':
    ensure => present,
    source => 'puppet:///modules/profile/solaris/scsi_vhci.conf',
  }
}
