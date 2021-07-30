class profile::time {
  class { 'ntp':
    package_ensure => 'latest',
  }

  if $facts['virtual'] == 'vmware' {
    # If we have the vmware tools installed, we can disable hypervisor timesync
    # from the node itself.

    # Note that we have to use bash because Debian doesn't ship a binary
    # version of `command`, and `/bin/sh` (`dash`) sometimes returns 127 when
    # `command` fails.
    exec { 'disable_guest_time_sync':
      command => 'vmware-toolbox-cmd timesync disable',
      onlyif  => 'bash -c "command -v vmware-toolbox-cmd && vmware-toolbox-cmd timesync status"',
      path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
    }
  }
}
