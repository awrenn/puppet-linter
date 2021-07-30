# A profile to manage nfs servers
class profile::nfs::server (
  $ensure       = present,
  $nfs_pkg_name = undef,
  $nfs_svc_name = $nfs_pkg_name,
  $nfs_exports = '/etc/exports'
) {

  include profile::nfs::client

  case $facts['os']['name'] {
    'Debian': {
      $nfs_pkg      = 'nfs-kernel-server'
      $nfs_service  = $nfs_pkg
      $nfs_services = $nfs_service
      $nobody       = 'nobody'
      $nogroup      = 'nogroup'
    }
    'CentOS': {
      $nfs_services = [
        'rpcbind',
        'nfs-server',
        'nfs-lock',
        'nfs-idmap',
      ]
      $nfs_service  = $nfs_services[1]
      $nobody       = 'nfsnobody'
      $nogroup      = $nobody
    }
    default: {
      if $nfs_pkg_name {
        $nfs_pkg      = $nfs_pkg_name
        $nfs_service  = $nfs_svc_name
        $nfs_services = $nfs_service
      }
      else {
        $no_server_support = [
          'nfs server support has not been configured',
          "for ${facts['os']['name']}. You may still",
          'use the server profile by specifying $nfs_pkg_name.',
        ]
        $no_server_support_m = join($no_server_support, ' ')
        notify { $no_server_support_m: }
      }
    }
  }

  if $nfs_pkg {
    package { $nfs_pkg:
      ensure => $ensure,
    }
  }

  concat { $nfs_exports:
    owner => $nobody,
    group => $nogroup,
    mode  => '0444',
  }

  concat::fragment { "${nfs_exports}_header":
    target  => $nfs_exports,
    content => "# HEADER: This file is managed by puppet\n",
    order   => 0,
  }

  service { $nfs_services:
    ensure    => running,
    subscribe => Concat[$nfs_exports],
    require   => Concat[$nfs_exports],
  }
}
