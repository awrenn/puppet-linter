#
# profile::docker
#
class profile::docker(
  $ensure = present,
  Optional[String[1]] $dm_basesize = undef,
  Optional[String[1]] $dm_loopdatasize = undef,
  Optional[String[1]] $dm_loopmetadatasize = undef,
  Optional[String[1]] $dm_thinpooldev = undef,
  Optional[Boolean] $dm_use_deferred_removal = undef,
  Optional[Boolean] $dm_use_deferred_deletion = undef,
  Optional[String[1]] $storage_driver = undef,
  Optional[Variant[String,Array]] $registry_mirror = 'https://artifactory.delivery.puppetlabs.net',
  Optional[String[1]] $docker_ce_cli_ensure = undef,
  Boolean $create_lvm_thinpool = false,
  Boolean $garbage_collection = false,
  String[1] $compose_version = '1.28.6',
  String[1] $log_driver = 'journald',
  Array $log_opt = [],
  Boolean $composer = false,
  Boolean $purge_docker_engine = false,
  Boolean $ensure_extras = false,
  Boolean $manually_manage_docker_repo = false,
  Boolean $prune_images = false,
  Array[String] $volumes = [],
  ){

  if $profile::server::monitoring {
    include profile::docker::monitor
  }

  if $create_lvm_thinpool {
    include profile::docker::lvm
  }

  realize(Group['docker'])

  if $purge_docker_engine {
    include profile::docker::purge
  }

  if $ensure_extras {
    if $facts['os']['name'] == 'CentOS' {
      ensure_resource('yumrepo', 'extras', {
        'ensure'     => 'present',
        'descr'      => 'CentOS-$releasever - Extras',
        'gpgcheck'   => '1',
        'gpgkey'     => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7',
        'mirrorlist' => 'http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra',
        'before'     => 'Package[docker]',
      })
    }
  }

  if $manually_manage_docker_repo {
    class { 'profile::docker::install':
      ensure      => $ensure,
      repo_ensure => absent,
    }
    $manage_package = false
    $use_upstream_package_source = false
  } else {
    $manage_package = true
    $use_upstream_package_source = true
  }

  class { 'docker':
    ensure                      => $ensure,
    dm_basesize                 => $dm_basesize,
    dm_loopdatasize             => $dm_loopdatasize,
    dm_loopmetadatasize         => $dm_loopmetadatasize,
    dm_thinpooldev              => $dm_thinpooldev,
    log_driver                  => $log_driver,
    log_opt                     => $log_opt,
    registry_mirror             => $registry_mirror,
    storage_driver              => $storage_driver,
    manage_package              => $manage_package,
    use_upstream_package_source => $use_upstream_package_source,
  }

  if $composer {
    class { 'profile::docker::compose':
      compose_version => $compose_version,
    }
  }

  if $docker_ce_cli_ensure {
    package { 'docker-ce-cli':
      ensure => $docker_ce_cli_ensure,
    }
  }

  if $garbage_collection {
    include profile::docker::garbage_collection
  }

  if $::profile::server::metrics {
    include profile::docker::metrics
  }

  if $prune_images {
    cron { 'prune docker images':
      command => '/usr/bin/docker image prune --all --force',
      user    => 'root',
      weekday => 0,
      hour    => 0,
      minute  => 30,
    }
  }

  if $volumes {
    file { '/docker_volumes/':
      ensure => directory,
    }
    $volumes.each |String $volume| {
      file { "/docker_volumes/${volume}":
        ensure => directory,
      }
    }
  }

  include profile::docker::registry
}
