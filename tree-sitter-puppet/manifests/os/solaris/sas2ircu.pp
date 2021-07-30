class profile::os::solaris::sas2ircu {

  $base_dir = '/opt/lsi'

  file {
    $base_dir:
      ensure => directory,
      mode   => '0400';
    "${base_dir}/sas2ircu":
      ensure => present,
      mode   => '0500',
      source => 'puppet:///modules/profile/solaris/sas2ircu',
  }
}
