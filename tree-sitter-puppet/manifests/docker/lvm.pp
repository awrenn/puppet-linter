# Configure LVM thinpool for direct-lvm docker storage
# Following directions from https://docs.docker.com/engine/userguide/storagedriver/device-mapper-driver/
#
class profile::docker::lvm (
  $physical_volume = '/dev/sdb',
  $volume_group = 'docker-lvm'
) {

  class { '::lvm':
    package_ensure => latest,
    manage_pkg     => true,
  }

  volume_group { $volume_group:
    physical_volumes => '/dev/sdb',
    require          => Exec["Create ${physical_volume}"],
  }

  $docker_thinpool_profile = "activation {
thin_pool_autoextend_threshold = 80
thin_pool_autoextend_percent = 20
}"

  file { '/etc/lvm/profile/docker-thinpool.profile':
    ensure  => present,
    content => $docker_thinpool_profile,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    require => Package['lvm2'],
  }

  exec {
    "Create ${physical_volume}":
      command => "/usr/sbin/pvcreate --force ${physical_volume}",
      unless  => "/usr/sbin/pvs ${physical_volume}",
      before  => Volume_group[$volume_group],
      require => Package['lvm2']
      ;
    "Create ${volume_group} thinpool volume":
      command => "/usr/sbin/lvcreate --wipesignatures y -n thinpool ${volume_group} -l 95%VG",
      unless  => "/usr/sbin/lvs ${volume_group}/thinpool",
      notify  => Exec["Create ${volume_group} thinpool metadata volume"]
      ;
    "Create ${volume_group} thinpool metadata volume":
      command     => "/usr/sbin/lvcreate --wipesignatures y -n thinpoolmeta ${volume_group} -l 1%VG",
      refreshonly => true,
      notify      => Exec["Convert ${volume_group} to unified thinpool"]
      ;
    "Convert ${volume_group} to unified thinpool":
      command     => "/usr/sbin/lvconvert -y --zero n -c 512K --thinpool ${volume_group}/thinpool --poolmetadata ${volume_group}/thinpoolmeta",
      refreshonly => true,
      notify      => Exec["Update ${volume_group} lvm profile"]
      ;
    "Update ${volume_group} lvm profile":
      command     => "/usr/sbin/lvchange --metadataprofile docker-thinpool ${volume_group}/thinpool",
      refreshonly => true
      ;
  }
}
