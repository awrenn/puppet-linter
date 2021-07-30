class profile::boot::pxe::tools (
  $tftp_root = $profile::boot::pxe::tftp_root,
  $breakin_version = '4.26.1-53',
  $breakin_bootimage_version = '4.26.1',
) {
  $artifactory = 'https://artifactory.delivery.puppetlabs.net/artifactory'
  $breakin_url = "${artifactory}/generic__iso/pxe_images/breakin-${breakin_version}.tbz2"

  $breakin_dir = "${tftp_root}/tools/breakin-${breakin_version}"

  $breakin_image_path = "tools/breakin-${breakin_version}/bootimage-${breakin_bootimage_version}"
  $breakin_kernel = "${breakin_image_path}/kernel-${breakin_bootimage_version}"
  $breakin_initrd = "${breakin_image_path}/initrd-${breakin_bootimage_version}.cpio.lzma"

  # sshpasswd below is also saved in 1password
  $breakin_ssh_password = 'apetrilogy'

  package { 'bzip2':
    ensure => 'present',
  }

  file { $breakin_dir:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => true,
    require => Class['Pxe::Tools'],
  }

  exec { "retrieve breakin ${breakin_version} image":
    path    => ['/usr/bin', '/usr/local/bin', '/bin'],
    command => "wget -q -O - ${breakin_url} | tar jxv -C ${breakin_dir}",
    creates => "${breakin_dir}/bootimage-${breakin_bootimage_version}",
    require => [Class['Pxe::Tools'], File[$breakin_dir], Package['bzip2']],
  }

  pxe::menu::entry { 'breakin (Test)':
    file   => 'menu_tools',
    kernel => $breakin_kernel,
    append => join([
      "initrd=${breakin_initrd}",
      "sshpasswd=${breakin_ssh_password} startup=breakin vga=1",
    ], ' '),
  }

  pxe::menu::entry { 'breakin (Rescue)':
    file   => 'menu_tools',
    kernel => $breakin_kernel,
    append => join([
      "initrd=${breakin_initrd}",
      "sshpasswd=${breakin_ssh_password} startup=rescue vga=1",
    ], ' '),
  }
}
