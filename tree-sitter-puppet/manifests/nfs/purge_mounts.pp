# Identify current mounts and purge stale entries.
# This is preferable to purging mount resource due to system entries
# that do not exist in puppet.
class profile::nfs::purge_mounts (
  $user = 'root',
  $home = '/root'
) {
  $volumes = puppetdb_query("resources { certname = '${trusted['certname']}' and type = 'Mount' }")
  $devices = $volumes.map |$volume| { $volume['parameters']['device'] }

  $script    = "${home}/diffmounts.py"
  $mounts    = "${home}/mounts"
  $command   = "${script} --mounts_file ${mounts}"

  file {
    $mounts:
      owner   => $user,
      group   => $user,
      mode    => '0444',
      content => $devices.sort().suffix("\n").join('')
      ;
    $script:
      owner  => 'root',
      group  => 'root',
      mode   => '0500',
      source => 'puppet:///modules/profile/nfs/diffmounts.py',
  }

  exec { 'purge_mounts':
    command => join([$command, '--update_fstab'], ' '),
    unless  => $command,
    user    => 'root',
    path    => '/usr/bin',
    require => [ File[$mounts], File[$script] ],
  }
}
