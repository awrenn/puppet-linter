# NOTE: The imaging automation modifies this file when updating existing pools
# or adding new ones. It assumes that the manifest is structured as <pre>, <pools>,
# <post> where <pre> represents the stuff before the pool resource declarations; <pools>
# are the pool resource declarations, while <post> is what comes after the pool resource
# declarations. Each section is separated by the <pool_separator>, which is "      ;" (the
# semi-colon at the bottom of each resource-like declaration)
#
# Thus when manually modifying this file, be careful that you do not break the expected
# <pre>, <pools>, and <post> structure. Note that things like adding new params. to pool
# resources are OK, because the structure is unchanged.

class profile::vmpooler::pools::cinext (
  String $folder_name,
  String $config_file,
  String $provider,
  String $datacenter,
  String $clone_target,
  String $datastore,
) {

  $base = regsubst($folder_name, '-', '_', 'G')

  profile::vmpooler::pool {
    default:
      datastore    => $datastore,
      folder_base  => $folder_name,
      provider     => $provider,
      datacenter   => $datacenter,
      config_file  => $config_file,
      base         => "${base}_",
      clone_target => $clone_target,
      ;
    "${base}_arista-4-i386":
      template => 'templates/arista-4-i386',
      size     => 0,
      ;
    "${base}_centos-5-i386":
      template => 'templates/centos-5-i386-0.0.1',
      size     => 0,
      ;
    "${base}_centos-5-x86_64":
      template => 'templates/centos-5-x86_64-0.0.1',
      size     => 0,
      ;
    "${base}_centos-6-i386":
      template => 'templates/centos-6.8-i386-0.0.2',
      size     => 0,
      ;
    "${base}_cisco-exr-9k-x86_64":
      pool_alias => 'cisco-exr-9k-64',
      template   => 'templates/cisco-exr-9k-x86_64',
      size       => 0,
      ;
    "${base}_cisco-nxos-7k-x86_64":
      pool_alias => 'cisco-nxos-7k-64',
      template   => 'templates/nxos-7k-centos_7.2_x64_86',
      size       => 0,
      ;
    "${base}_cisco-nxos-9k-x86_64":
      pool_alias => 'cisco-nxos-9k-64',
      template   => 'templates/cisco-nxos-9k-x86_64',
      size       => 0,
      ;
    "${base}_cisco-wrlinux-5-x86_64":
      pool_alias => 'cisco-wrlinux-5-64',
      template   => 'templates/cisco-wrlinux-5-x86_64',
      size       => 0,
      ;
    "${base}_cisco-wrlinux-7-x86_64":
      pool_alias => 'cisco-wrlinux-7-64',
      template   => 'templates/cisco-wrlinux-7-x86_64',
      size       => 0,
      ;
    "${base}_cisco-ios-xr-6.3.1-x86-64":
      pool_alias => 'cisco-ios-xr-6.3.1-x86-64',
      template   => 'templates/cisco-ios-xr-6.3.1-x86-64',
      size       => 0,
      ;
    "${base}_cumulus-vx-25-x86_64":
      pool_alias => 'cumulus-vx-25-64',
      template   => 'templates/cumulus-vx-25-x86_64',
      size       => 0,
      ;
    "${base}_fedora-14-i386":
      template => 'templates/fedora-14-i386',
      size     => 0,
      ;
    "${base}_opensuse-11-i386":
      template => 'templates/opensuse-11-i386',
      size     => 0,
      ;
    "${base}_opensuse-11-x86_64":
      template => 'templates/opensuse-11-x86_64',
      size     => 0,
      ;
    "${base}_oracle-5-i386":
      template => 'templates/oracle-5-i386',
      size     => 0,
      ;
    "${base}_oracle-5-x86_64":
      template => 'templates/oracle-5-x86_64',
      size     => 0,
      ;
    "${base}_oracle-6-i386":
      template => 'templates/oracle-6-i386',
      size     => 0,
      ;
    "${base}_oracle-6-x86_64":
      template => 'templates/oracle-6-x86_64',
      size     => 0,
      ;
    "${base}_palo-alto-6.1.0-x86_64":
      template => 'templates/palo-alto-6.1.0-x86_64',
      size     => 0,
      ;
    "${base}_palo-alto-7.1.0-x86_64":
      template => 'templates/palo-alto-7.1.0-x86_64',
      size     => 0,
      ;
    "${base}_palo-alto-8.1.0-x86_64":
      template => 'templates/palo-alto-8.1.0-x86_64',
      size     => 0,
      ;
    "${base}_redhat-5-i386":
      template => 'templates/redhat-5-i386-0.0.1',
      size     => 0,
      ;
    "${base}_redhat-5-x86_64":
      template => 'templates/redhat-5-x86_64-0.0.1',
      size     => 0,
      ;
    "${base}_redhat-6-i386":
      template => 'templates/redhat-6.8-i386-0.0.4',
      size     => 0,
      ;
    "${base}_scientific-5-i386":
      template => 'templates/scientific-5-i386',
      size     => 0,
      ;
    "${base}_scientific-5-x86_64":
      template => 'templates/scientific-5-x86_64',
      size     => 0,
      ;
    "${base}_scientific-6-i386":
      template => 'templates/scientific-6.8-i386-0.0.2',
      size     => 0,
      ;
    "${base}_scientific-6-x86_64":
      template => 'templates/scientific-6.8-x86_64-0.0.2',
      size     => 0,
      ;
    "${base}_sles-11-i386":
      template => 'templates/sles-11-i386-0.0.4',
      size     => 0,
      ;
    "${base}_sles-11-x86_64":
      template => 'templates/sles-11-x86_64-0.0.5',
      size     => 0,
      ;
    "${base}_solaris-10-u8-x86_64":
      template => 'templates/solaris-10-u8-x86_64',
      size     => 0,
      ;
    "${base}_solaris-10-x86_64":
      template => 'templates/solaris-10-x86_64-0.0.1',
      size     => 0,
      ;
    "${base}_solaris-11-x86_64":
      template => 'templates/solaris-11-x86_64-0.0.2',
      size     => 0,
      ;
    "${base}_solaris-112-x86_64":
      template => 'templates/solaris-112-x86_64-0.0.2',
      size     => 0,
      ;
  }
}
