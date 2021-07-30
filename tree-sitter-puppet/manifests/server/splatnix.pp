class profile::server::splatnix {
  include profile::base
  include profile::sysop

  if $facts['kernel'] == 'Linux' {
    include pe_patch
  }

  file { '/srv':
    ensure => directory,
    mode   => '0755',
    owner  => 'root',
    group  => '0',
  }

  # Do less if we are testing on virtualbox
  if $facts['virtual'] != 'virtualbox' {

    unless $facts['os']['family'] == 'Suse' {
      include profile::mail
    }

    unless $facts['kernel'] == 'Darwin' {
      include profile::time
    }

    if $facts['kernel'] == 'Linux' {
      include profile::pe::comply
    }

    if (($facts['virtual']  == 'kvm') and ($facts['dmi']['bios']['vendor'] == 'Google')) {
      include profile::gce
    }

    if $profile::server::logging {
      case $facts['kernel'] {
        'SunOS': {
          notify { 'Currently no support for Class[profile::logging::rsyslog::client] on our Solaris plaform': }
        }
        default: {
          include profile::logging::rsyslog::client
        }
      }
    }

    if $profile::server::logging or $profile::server::promtail {
      # Confined to just Linux for now as other OS's have not been added to the
      # promtail module as of 2019-10-4
      if $facts['kernel'] == 'Linux' {
        include profile::logging::promtail
      }
    }

    if $profile::server::fluentd {
      include profile::logging::fluentd
    }

    if $profile::server::fw {
      case $facts['kernel'] {
        'Darwin': {
          notify { 'Currently no support for Class[profile::fw] on our macOS plaform': }
        }
        'SunOS': {
          notify { 'Currently no support for Class[profile::fw] on our Solaris plaform': }
        }
        default: {
          include profile::fw
        }
      }
    }

    # Only purge firewall rules if the firewall is being managed
    if $profile::server::fw and $profile::server::fw_purge {
      case $facts['kernel'] {
        'SunOS': {
          notify { 'Currently no support for Class[profile::fw::purge] on our Solaris plaform': }
        }
        default: {
          include profile::fw::purge
        }
      }
    }

    if $profile::server::monitoring {
      include profile::server::monitor
    }

    if $profile::server::metrics {
      include profile::metrics
      Class['profile::base'] -> Class['profile::metrics']
    }

    # Include any operating system specific server configuration
    case $facts['kernel'] {
      'Darwin': { include profile::server::darwin }
      default : {}
    }
  }

}
