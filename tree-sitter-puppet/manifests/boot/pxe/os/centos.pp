#
# profile::boot::pxe::os::centos creates the menu and loads the install files
# for all versions of centos listed in the array from hiera,
# profile::boot::pxe::os::centos::versions.
#
class profile::boot::pxe::os::centos (
  Array[String[1], 1] $architectures,
  Array[String[1], 1] $versions,
  String[1]           $password_hash,
) {

  $versions.each |$ver| {
    $os = 'centos'

    file { "/webroot/centos/${ver}":
      ensure => directory,
    }

    $architectures.each |$arch| {
      $canonical_hostname = $facts['networking']['fqdn']

      pxe::installer { "${os}_${ver}_${arch}":
        arch   => $arch,
        ver    => $ver,
        os     => $os,
        file   => "os_${os}",
        kernel => "images/${os}/${ver}/${arch}/vmlinuz",
        append => "initrd=images/${os}/${ver}/${arch}/initrd.img method=http://mirror.centos.org/centos-7/${ver}/os/x86_64/ devfs=nomount ip=dhcp ks=http://${canonical_hostname}/centos/${ver}/ks.cfg vga=792 servername=replace_me",
      }

      file { "/webroot/centos/${ver}/ks.cfg":
        ensure  => 'file',
        content => epp('profile/boot/pxe/centos/ks.cfg.epp', {
          'dns_servers'    => lookup('profile::network::nameservers'),
          'ntp_servers'    => lookup('ntp::servers'),
          'centos_version' => $ver,
          'password_hash'  => $password_hash,
          'puppet_server'  => lookup('profile::base::puppet::ca_server'),
        }),
      }
    }
  }


}
