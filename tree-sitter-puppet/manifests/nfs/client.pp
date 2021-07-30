# A profile to manage nfs clients
class profile::nfs::client (
  $ensure       = present,
  $nfs_pkg_name = undef
) {

  case $facts['os']['name'] {
    'Debian': {
      $nfs_pkg = 'nfs-common'
    }
    'CentOS': {
      $nfs_pkg = 'nfs-utils'
    }
    default: {
      if $nfs_pkg_name {
        $nfs_pkg = $nfs_pkg_name
      }
      else {
        $no_client_support = [
          'nfs client support has not been configured',
          "for ${facts['os']['name']}. You may still",
          'use the client profile by specifying $nfs_pkg_name.',
        ]
        $no_client_support_m = join( $no_client_support, ' ' )
        notify { $no_client_support_m: }
      }
    }
  }

  if $nfs_pkg {
    package { $nfs_pkg:
      ensure => $ensure,
    }
  }
}
