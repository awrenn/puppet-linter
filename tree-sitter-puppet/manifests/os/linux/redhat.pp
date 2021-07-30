##
#
class profile::os::linux::redhat (
  $exclude_packages = [],
) {

  include cron
  include profile::os::linux::redhat::inotify_watches

  exec { 'clean yum':
    command     => 'yum clean metadata --disablerepo=pe_repo,puppet_enterprise',
    path        => ['/usr/sbin', '/sbin', '/usr/bin', '/bin'],
    refreshonly => true,
    notify      => Exec['generate yum cache'],
  }
  exec { 'generate yum cache':
    command     => 'yum makecache fast --disablerepo=pe_repo,puppet_enterprise',
    path        => ['/usr/sbin', '/sbin', '/usr/bin', '/bin'],
    refreshonly => true,
  }
  Yumrepo<| title != 'puppet_enterprise' and title != 'pe_repo' |> ~> Exec['clean yum']

  if $facts['os']['distro']['release']['major'] {
    case $facts['os']['name'] {
      'redhat':  { include profile::os::linux::redhat::el }
      'centos':  { include profile::os::linux::redhat::centos }
      default: { notify { "Linux distribution ${facts['os']['name']} is not currently supported by Puppet Labs Operations": } }
    }

    if $facts['os']['distro']['release']['major'] == '6' {
      # service is in /usr/sbin/service everywhere else.
      file { '/usr/sbin/service':
        ensure => link,
        target => '/sbin/service',
      }

      # This will create /etc/sysconfig/network-scripts/ifcfg-eth0 if
      # it doesn't already exist, breaking networking in RHEL 7.
      ini_setting { 'manage RedHat DHCP hostname':
        ensure  => present,
        section => '',
        path    => '/etc/sysconfig/network-scripts/ifcfg-eth0',
        setting => 'DHCP_HOSTNAME',
        value   => "\"${facts['networking']['hostname']}\"",
      }
    }
  }

  $packages = delete([
    'ca-certificates',
    'redhat-lsb-core',
    'yum-plugin-versionlock',
    'yum-utils',
  ], $exclude_packages)

  package { $packages:
    ensure => latest,
  }

  # RHEL/CentOS 6 only has a single openssl package.
  $ssl_packages = delete($::os_maj_version ? {
    '7'     => ['openssl', 'openssl-libs'],
    default => ['openssl'],
  }, $exclude_packages)

  package { $ssl_packages:
    ensure => latest,
  }
}
