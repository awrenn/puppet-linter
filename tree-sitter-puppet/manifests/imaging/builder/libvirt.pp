class profile::imaging::builder::libvirt {

  $package_list = [
    'qemu',
    'libvirt',
    'seabios',
  ]

  package { $package_list:
    ensure => 'installed',
  }
}
