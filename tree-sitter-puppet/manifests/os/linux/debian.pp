##
#
class profile::os::linux::debian (
  $autoupdates = true
) {

  if $facts['os']['name'] == 'CumulusLinux' {
    $packages = []
  } else {
    $packages = [
      'lsb-release',
      'keychain',
      'ca-certificates',
      'less',
      'apt',
      'debian-goodies',
      'needrestart',
    ]
  }

  package { $packages: ensure => latest }

  # this is a workaround so that cron isn't auto-updated
  # because cron updates seem to corrupt dpkg when updates runs from cron
  package { 'cron':
    ensure => present,
  }

  # Lets always ensure libssl1.0.0 and openssl are the latest version
  $libssl_package = $facts['os']['release']['major'] ? {
    '10'    => 'libssl1.1',
    '9'     => 'libssl1.0.2',
    '7'     => 'libssl1.0.0',
    '6'     => 'libssl0.9.8',
    default => 'libssl1.0.0',
  }

  package { [$libssl_package, 'openssl']:
    ensure => 'latest',
  }

  if ! $facts['has_nfs'] {
    package { 'rpcbind': ensure => absent }
  }

  unless $facts['os']['name'] == 'CumulusLinux' {
    # Enable sysstat and recap
    include sysstat
  }

  # For some reason, we keep getting mpt installed on things. Not
  # cool.
  if $::is_virtual == 'true' or $::is_virtual == true {
    package { 'mpt-status': ensure => absent }
  }

  # ----------
  # Apt Configuration
  # ----------
  include profile::apt

  file { '/etc/apt/apt.conf':
    ensure => absent,
  }

  # Keep the installed packages to a minimum
  apt::conf { 'norecommends':
    priority => '00',
    content  => "Apt::Install-Recommends 0;\nApt::AutoRemove::InstallRecommends 1;\n",
  }

  include profile::base::puppet

  $cron_minute = $::profile::base::puppet::cron_minute ? {
    Array[Integer[0,59], 1]                      => $::profile::base::puppet::cron_minute[0],
    Integer[0,59]                                => $::profile::base::puppet::cron_minute,
    default                                      => 0,
  }
  cron { 'apt-get update':
    ensure  => present,
    command => '/usr/bin/apt-get -qq update',
    user    => 'root',
    minute  => ($cron_minute + 5) % 60,
    hour    => '*/2',
  }

  case $facts['os']['name'] {
    'CumulusLinux': { include profile::os::linux::debian::cumuluslinux }
    'Debian':       {
      include profile::os::linux::debian::vanilla
      include profile::os::linux::debian::autoupdates
    }
    'Ubuntu':       { include profile::os::linux::debian::ubuntu }
    default:        { notify { "Linux distribution ${facts['os']['name']} is not currently supported by Puppet Labs Operations": } }
  }
}
