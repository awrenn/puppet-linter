class profile::dhcp::monitor inherits ::profile::monitoring::icinga2::common {

  $primaryserver = lookup('profile::dhcp::primaryserver')

  icinga2::object::service { 'check-dhcp-config':
    check_command => 'check-exit',
    vars          => {
      'run_command' => '/usr/sbin/dhcpd -q -t',
    },
  }

  # Check leases free on the dhcp primary hosts
  if $facts['networking']['fqdn'] == $primaryserver {
    icinga2::object::service { 'check-dhcp-leases':
      check_command => 'check_leases',
      vars          => {
        'file'     => '/tmp/pool-output.1',
        'warning'  => '90',
        'critical' => '95',
      },
    }
  }
}
