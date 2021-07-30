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
#
# NOTE: The purpose of cinext_pix is to provide available pools from a provider other than
# ci65. Here, vc7 is the provider. This is to ensure that our CI system keeps running when e.g.
# ci65 goes down. However, pools in vmpooler must have unique names; many of these pools are declared
# in cinext.pp.
class profile::vmpooler::pools::cinext_pix (
  String $folder_name,
  String $config_file,
  String $provider,
  String $datacenter,
  String $clone_target,
  String $datastore,
  String $snapshot_mainmem_ioblockpages,
  String $snapshot_mainmem_iowait
) {

  $base = regsubst($folder_name, '-', '_', 'G')

  profile::vmpooler::pool {
    default:
      provider                      => $provider,
      datacenter                    => $datacenter,
      clone_target                  => $clone_target,
      datastore                     => $datastore,
      folder_base                   => $folder_name,
      config_file                   => $config_file,
      base                          => "${base}_",
      snapshot_mainmem_ioblockpages => $snapshot_mainmem_ioblockpages,
      snapshot_mainmem_iowait       => $snapshot_mainmem_iowait
      ;
    "${base}_centos-6-x86_64":
      template => 'templates/netapp/acceptance2/centos-6.8-x86_64-0.0.2-8gb',
      size     => 0,
      timeout  => 5,
      ;
    "${base}_centos-7-x86_64":
      template => 'templates/netapp/acceptance2/centos-7.2-x86_64-0.0.6-8gb',
      size     => 0,
      timeout  => 5,
      ;
    "${base}_centos-7.2-mono-2018.1.15-preload-x86_64":
      template => 'templates/netapp/acceptance2/centos-7.2-mono-2018.1.15-preload-x86_64-0.0.14',
      size     => 0,
      ;
    "${base}_centos-7.2-tmpfs-x86_64":
      template => 'templates/netapp/acceptance2/centos-7.2-tmpfs-x86_64-0.0.1',
      size     => 0,
      ;
    "${base}_centos-8-pdbpreload-x86_64":
      template => 'templates/netapp/acceptance2/centos-8-pdbpreload-x86_64-0.0.4',
      size     => 0,
      ;
    "${base}_centos-8-x86_64":
      template => 'templates/netapp/acceptance2/centos-8-x86_64-0.0.2',
      size     => 0,
      ;
    "${base}_centos-8.3-kurl-beta-x86_64":
      template => 'templates/netapp/acceptance2/centos-8.3-kurl-beta-x86_64-0.1.1',
      size     => 0,
      ;
    "${base}_debian-10-x86_64":
      template => 'templates/netapp/acceptance2/debian-10-x86_64-0.0.2',
      size     => 0,
      ;
    "${base}_debian-11-x86_64":
      template => 'templates/debian-11-x86_64-0.0.1',
      size     => 0,
      ;
    "${base}_debian-7-i386":
      template => 'templates/netapp/acceptance2/debian-7-i386',
      size     => 0,
      ;
    "${base}_debian-7-x86_64":
      template =>  'templates/netapp/acceptance2/debian-7-x86_64',
      size     => 0,
      ;
    "${base}_debian-8-i386":
      template =>  'templates/netapp/acceptance2/debian-8-i386-0.0.6',
      size     => 0,
      ;
    "${base}_debian-8-x86_64":
      template =>  'templates/netapp/acceptance2/debian-8-x86_64-0.0.8',
      size     => 0,
      ;
    "${base}_debian-9-i386":
      template =>  'templates/netapp/acceptance2/debian-9-i386',
      size     => 0,
      ;
    "${base}_debian-9-x86_64":
      template =>  'templates/netapp/acceptance2/debian-9-x86_64',
      size     => 0,
      ;
    "${base}_fedora-28-x86_64":
      template => 'templates/netapp/acceptance2/fedora-28-x86_64-0.0.4',
      size     => 0,
      ;
    "${base}_fedora-29-x86_64":
      template => 'templates/netapp/acceptance2/fedora-29-x86_64-0.0.1',
      size     => 0,
      ;
    "${base}_fedora-30-x86_64":
      template => 'templates/netapp/acceptance2/fedora-30-x86_64-0.0.1',
      size     => 0,
      ;
    "${base}_fedora-31-x86_64":
      template => 'templates/netapp/acceptance2/fedora-31-x86_64-0.0.1',
      size     => 0,
      ;
    "${base}_fedora-32-x86_64":
      template => 'templates/netapp/acceptance2/fedora-32-x86_64-0.0.1',
      size     => 0,
      ;
    "${base}_fedora-34-x86_64":
      template => 'templates/netapp/acceptance2/fedora-34-x86_64-0.0.2',
      size     => 0,
      ;
    "${base}_macos-112-x86_64":
      clone_target => 'mac2',
      template     => 'templates/macos-112-x86_64-0.0.1',
      size         => 0,
      datastore    => 'tintri-vmpooler-pix'
      ;
    "${base}_oracle-7-x86_64":
      template => 'templates/netapp/acceptance2/oracle-7-x86_64',
      size     => 0,
      timeout  => 10,
      ;
    "${base}_osx-1010-x86_64":
      clone_target => 'mac2',
      template     => 'templates/osx-1010-x86_64',
      size         => 0,
      datastore    => 'tintri-vmpooler-pix'
      ;
    "${base}_osx-1011-x86_64":
      clone_target => 'mac2',
      template     => 'templates/osx-1011-x86_64',
      size         => 0,
      datastore    => 'tintri-vmpooler-pix'
      ;
    "${base}_osx-1012-x86_64":
      clone_target => 'mac2',
      template     => 'templates/osx-1012-x86_64',
      size         => 0,
      datastore    => 'tintri-vmpooler-pix'
      ;
    "${base}_osx-1013-x86_64":
      clone_target => 'mac2',
      template     => 'templates/macos-1013-x86_64-0.1.0',
      size         => 0,
      datastore    => 'tintri-vmpooler-pix'
      ;
    "${base}_osx-1014-x86_64":
      clone_target => 'mac2',
      template     => 'templates/osx-1014-x86_64-0.0.2',
      size         => 0,
      datastore    => 'tintri-vmpooler-pix'
      ;
    "${base}_osx-1015-x86_64":
      clone_target => 'mac2',
      template     => 'templates/macos-1015-x86_64-0.0.1',
      size         => 0,
      datastore    => 'tintri-vmpooler-pix'
      ;
    "${base}_redhat-6-x86_64":
      template => 'templates/netapp/acceptance2/redhat-6.8-x86_64-0.0.5-8gb',
      size     => 0,
      ;
    "${base}_redhat-7-x86_64":
      template => 'templates/netapp/acceptance2/redhat-7.2-x86_64-0.0.7-8gb',
      size     => 0,
      ;
    "${base}_redhat-8-x86_64":
      template => 'templates/netapp/acceptance2/redhat-8-x86_64-0.0.4-8gb',
      size     => 0,
      ;
    "${base}_redhat-fips-7-x86_64":
      template => 'templates/netapp/acceptance2/redhat-fips-7.2-x86_64-0.0.9-8gb',
      size     => 0,
      ;
    "${base}_redhat-fips-7-x86_64-ipv6":
      template => 'templates/netapp/acceptance2/redhat-fips-7.2-x86_64-0.0.8-ipv6-8gb',
      size     => 0,
      ;
    "${base}_scientific-7-x86_64":
      template => 'templates/netapp/acceptance2/scientific-7-x86_64',
      size     => 0,
      ;
    "${base}_sles-12-x86_64":
      template => 'templates/netapp/acceptance2/sles-12-x86_64-8gb',
      size     => 0,
      ;
    "${base}_sles-15-x86_64":
      template => 'templates/netapp/acceptance2/sles-15-x86_64-0.0.4',
      size     => 0,
      ;
    "${base}_solaris-114-x86_64":
      template => 'templates/netapp/acceptance2/solaris-114-x86_64-0.0.5',
      size     => 0,
      ;
    "${base}_ubuntu-1404-i386":
      template => 'templates/netapp/acceptance2/ubuntu-14.04-i386-0.0.7',
      size     => 0,
      ;
    "${base}_ubuntu-1404-x86_64":
      template => 'templates/netapp/acceptance2/ubuntu-14.04-x86_64-0.0.7',
      size     => 0,
      ;
    "${base}_ubuntu-1604-i386":
      template => 'templates/netapp/acceptance2/ubuntu-16.04-i386-0.0.8',
      size     => 0,
      ;
    "${base}_ubuntu-1604-x86_64":
      template => 'templates/netapp/acceptance2/ubuntu-16.04-x86_64-0.0.8-8gb',
      size     => 0,
      ;
    "${base}_ubuntu-1804-x86_64":
      template => 'templates/netapp/acceptance2/ubuntu-1804-x86_64-0.0.12',
      size     => 0,
      ;
    "${base}_ubuntu-1810-x86_64":
      template => 'templates/netapp/acceptance2/ubuntu-1810-x86_64-0.0.5',
      size     => 0,
      ;
    "${base}_ubuntu-2004-x86_64":
      template => 'templates/netapp/acceptance2/ubuntu-2004-x86_64-0.0.8',
      size     => 0,
      ;
    "${base}_vro-6-x86_64":
      template => 'templates/netapp/acceptance2/vro-6-x86_64',
      size     => 0,
      ;
    "${base}_vro-7-x86_64":
      template => 'templates/netapp/acceptance2/vro-7-x86_64',
      size     => 0,
      ;
    "${base}_vro-71-x86_64":
      template => 'templates/netapp/acceptance2/vro-7.1-x86_64-0.0.2',
      size     => 0,
      ;
    "${base}_vro-73-x86_64":
      template => 'templates/netapp/acceptance2/vro-7.3-x86_64-0.0.8',
      size     => 0,
      ;
    "${base}_vro-74-x86_64":
      template => 'templates/netapp/acceptance2/vro-7.4-x86_64-0.0.2',
      size     => 0,
      ;
    "${base}_win-10-1511-x86_64" :
      template => 'templates/netapp/acceptance2/win-10-1511-x86_64-20201113',
      size     => 0,
      ;
    "${base}_win-10-1607-x86_64" :
      template => 'templates/netapp/acceptance2/win-10-1607-x86_64-20201113',
      size     => 0,
      ;
    "${base}_win-10-1809-x86_64" :
      template => 'templates/netapp/acceptance2/win-10-1809-x86_64-20201113',
      size     => 0,
      ;
    "${base}_win-10-ent-i386" :
      template => 'templates/netapp/acceptance2/win-10-ent-i386-20201113',
      size     => 0,
      ;
    "${base}_win-10-ent-x86_64" :
      template => 'templates/netapp/acceptance2/win-10-ent-x86_64-20201113',
      size     => 0,
      ;
    "${base}_win-10-next-i386" :
      template => 'templates/netapp/acceptance2/win-10-next-i386-20201113',
      size     => 0,
      ;
    "${base}_win-10-next-x86_64" :
      template => 'templates/netapp/acceptance2/win-10-next-x86_64-20201113',
      size     => 0,
      ;
    "${base}_win-10-pro-x86_64" :
      template => 'templates/netapp/acceptance2/win-10-pro-x86_64-20201113',
      size     => 0,
      ;
    "${base}_win-2008-x86_64" :
      template => 'templates/netapp/acceptance2/win-2008-x86_64-20200121',
      size     => 0,
      ;
    "${base}_win-2008r2-x86_64" :
      template => 'templates/netapp/acceptance2/win-2008r2-x86_64-20200121',
      size     => 0,
      ;
    "${base}_win-2012-x86_64":
      template => 'templates/netapp/acceptance2/win-2012-x86_64-20201113',
      size     => 0,
      ;
    "${base}_win-2012r2-core-x86_64" :
      template => 'templates/netapp/acceptance2/win-2012r2-core-x86_64-20201113',
      size     => 0,
      ;
    "${base}_win-2012r2-fips-x86_64":
      template => 'templates/netapp/acceptance2/win-2012r2-fips-x86_64-20201113',
      size     => 0,
      ;
    "${base}_win-2012r2-wmf5-x86_64" :
      template => 'templates/netapp/acceptance2/win-2012r2-wmf5-x86_64-20201113',
      size     => 0,
      ;
    "${base}_win-2012r2-x86_64":
      template => 'templates/netapp/acceptance2/win-2012r2-x86_64-20201113',
      size     => 0,
      ;
    "${base}_win-2016-core-x86_64" :
      template => 'templates/netapp/acceptance2/win-2016-core-x86_64-20201113',
      size     => 0,
      ;
    "${base}_win-2016-x86_64" :
      template => 'templates/netapp/acceptance2/win-2016-x86_64-20201113',
      size     => 0,
      ;
    "${base}_win-2016-x86_64-ipv6" :
      template => 'templates/netapp/acceptance2/win-2016-x86_64-20201113-ipv6',
      size     => 0,
      ;
    "${base}_win-2019-core-x86_64":
      template => 'templates/netapp/acceptance2/win-2019-core-x86_64-20201113',
      size     => 0,
      ;
    "${base}_win-2019-fr-x86_64":
      template => 'templates/netapp/acceptance2/win-2019-fr-x86_64-20201113',
      size     => 0,
      ;
    "${base}_win-2019-ja-x86_64":
      template => 'templates/netapp/acceptance2/win-2019-ja-x86_64-20201113',
      size     => 0,
      ;
    "${base}_win-2019-x86_64" :
      template => 'templates/netapp/acceptance2/win-2019-x86_64-20201113',
      size     => 0,
      ;
    "${base}_win-7-x86_64" :
      template => 'templates/netapp/acceptance2/win-7-x86_64-20200121',
      size     => 0,
      ;
    "${base}_win-81-x86_64" :
      template => 'templates/netapp/acceptance2/win-81-x86_64-20201113',
      size     => 0,
      ;
  }
}
