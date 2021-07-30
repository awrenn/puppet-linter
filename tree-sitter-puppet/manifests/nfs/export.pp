# A define to build nfs exports
define profile::nfs::export (
  $allow_ip,
  $export_path = $title,
  $nfs_exports = '/etc/exports',
  $permissions = [ 'rw', 'sync', 'no_subtree_check' ]
) {

  include profile::nfs::server

  if is_array($permissions) {
    $nfs_options = join($permissions, ',')
  }
  else {
    $nfs_options = $permissions
  }

  if is_array($allow_ip) {
    each($allow_ip) |$a| {
      $nfs_export  = "${export_path} ${a}(${nfs_options})\n"
      concat::fragment { "${title}_${a}":
        target  => $nfs_exports,
        content => $nfs_export,
      }
    }
  }
  else {
    $nfs_export  = "${export_path} ${allow_ip}(${nfs_options})\n"
    concat::fragment { $title:
      target  => $nfs_exports,
      content => $nfs_export,
    }
  }
}
