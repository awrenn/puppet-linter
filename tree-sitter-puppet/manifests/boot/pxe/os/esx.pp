#
# profile::boot::pxe::os::esxi downloads the iso's and creates a pxe menu
# for installing esxi on a server.  This profile is substantially different
# from the centos and debian profiles as the pxe plugin doesn't support esx.
#
class profile::boot::pxe::os::esx (
  Array[String[1], 1] $versions,
  Array[String[1], 1] $vendors,
  String[1]           $password_hash,
) {
  $baseurl = 'https://artifactory.delivery.puppetlabs.net/artifactory/generic__iso/iso/'

  pxe::menu { 'ESXi':
    root => 'menu_install',
    file => 'os_esxi',
  }

  #
  # Unfortunately the xaque208/puppet-pxe does not support esxi, so we have to
  # emulate what it's doing.  I have uploaded the esxi iso's to artifactory to
  # back this.
  #

  $os         = 'esxi'
  $purposes = [
    'ci',
    'static',
  ]

  file { "${pxe::tftp_root}/images":
    ensure => 'directory',
  }

  file { "${pxe::tftp_root}/images/${os}":
    ensure => 'directory',
  }

  $versions.each |$ver| {
    file { "${pxe::tftp_root}/images/${os}/${ver}":
      ensure => 'directory',
    }

    file { "/webroot/${os}/${ver}":
      ensure => 'directory',
    }

    $vendors.each |$vendor| {
      $image_name = "VMware-VMvisor-Installer-${ver}-${vendor}.iso"

      file { "/webroot/${os}/${ver}/${vendor}":
        ensure => 'directory',
      }

      $esxi_instance_parent_path = "${pxe::tftp_root}/images/${os}/${ver}/${vendor}"
      file { $esxi_instance_parent_path:
        ensure => 'directory',
      }

      $esxi_instance_config_path = "${pxe::tftp_root}/images/${os}/${ver}/${vendor}/cfg"
      file { $esxi_instance_config_path:
        ensure => 'directory',
      }

      $esxi_instance_mounting_path = "${pxe::tftp_root}/images/${os}/${ver}/${vendor}/disk"
      file { $esxi_instance_mounting_path:
        ensure => 'directory',
      }

      $wget_esxi_iso      = "wget iso for ${os} ${vendor} ${ver}"
      $iso_in_tftp_folder = "${pxe::tftp_root}/images/${os}/${ver}/${image_name}"
      exec { $wget_esxi_iso:
        path    => ['/usr/bin', '/usr/local/bin'],
        cwd     => "${pxe::tftp_root}/images/${os}/${ver}/",
        command => "wget ${baseurl}/${image_name}",
        creates => $iso_in_tftp_folder,
        require => File[$esxi_instance_parent_path],
      }

      #
      # An older version of this implementation used 7z to extract the iso
      # rather than mount the iso, however, 7z preserves the iso9660 standard
      # of keeping all filenames capitalized which doesn't jive with the lower
      # case names that the config files use.  When you mount the folder,
      # it mounts with the original lower-case filenames.
      #
      mount { $esxi_instance_mounting_path:
        ensure  => 'mounted',
        device  => $iso_in_tftp_folder,
        fstype  => 'iso9660',
        options => 'ro',
        require => [
          Exec[$wget_esxi_iso],
          File[$esxi_instance_mounting_path],
        ],
      }

      $purposes.each |$purpose| {
        file { "/webroot/${os}/${ver}/${vendor}/${purpose}":
          ensure => 'directory',
        }

        file { "${pxe::tftp_root}/images/${os}/${ver}/${vendor}/cfg/${purpose}":
          ensure => 'directory',
        }

        tftp::file { "images/${os}/${ver}/${vendor}/cfg/${purpose}/boot.cfg":
          ensure  => 'file',
          content => epp("profile/boot/pxe/${os}/boot.cfg.epp", {
            'esxi_directory_prefix' => "images/${os}/${ver}/${vendor}/disk",
            'esxi_version'          => $ver,
            'ip_address'            => $facts['primary_ip'],
            'purpose'               => $purpose,
            'vendor'                => $vendor,
          }),
        }

        file { "/webroot/${os}/${ver}/${vendor}/${purpose}/ks.cfg":
          ensure  => 'file',
          content => epp('profile/boot/pxe/esxi/ks.cfg.epp', {
            'dns_servers'   => lookup('profile::network::nameservers'),
            'esxi_version'  => $ver,
            'ntp_servers'   => lookup('ntp::servers'),
            'password_hash' => $password_hash,
            'purpose'       => $purpose,
            'syslog_server' => lookup('syslog::server'),
            'vendor'        => $vendor,
          }),
        }
        pxe::menu::entry { "Install ESXI ${ver} for ${vendor} on ${purpose}":
          file   => 'os_esxi',
          kernel => "images/${os}/${ver}/${vendor}/disk/mboot.c32",
          append => "-c /images/${os}/${ver}/${vendor}/cfg/${purpose}/boot.cfg",
        }
      }
    }
  }
}
