class profile::repo::monitor(
  Array[String] $partitions
) inherits ::profile::monitoring::icinga2::common {
  icinga2::object::service { 'PE-build-volumes':
    check_command => 'disk',
    vars          => {
      'disk_partitions'       => $partitions,
      'disk_local'            => true,
      'disk_wfree'            => '6%',
      'disk_cfree'            => '3%',
      'disk_inode_wfree'      => '6%',
      'disk_inode_cfree'      => '3%',
      'disk_ignore_ereg_path' => '/var/lib/docker/aufs',
      'escalate'              => true,
    },
  }
}
