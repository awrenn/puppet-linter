#
# profile::boot::pxe::os::debian creates the menu and loads the install files
# for all versions of debian listed in the array from hiera,
# profile::boot::pxe::os::debian::versions.
#
class profile::boot::pxe::os::debian(
  Array[String[1], 1] $versions,
  Array[String[1], 1] $architectures,

) {

  $versions.each |$ver| {
    $os = 'debian'

    $architectures.each |$arch| {
      pxe::installer { "${os}_${ver}_${arch}":
        arch   => $arch,
        ver    => $ver,
        os     => $os,
        file   => "os_${os}",
        kernel => "images/${os}/${ver}/${arch}/linux",
        append => "initrd=images/${os}/${ver}/${arch}/initrd.gz text",
      }
    }
  }
}
