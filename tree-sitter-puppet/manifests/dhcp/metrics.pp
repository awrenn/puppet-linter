class profile::dhcp::metrics {

  $primaryserver = lookup('profile::dhcp::primaryserver')

  # Set up dhcp pools to graphite, only installed on primary servers
  if $facts['networking']['fqdn'] == $primaryserver {
    file { '/root/dhcp-to-graphite.py':
      ensure => file,
      mode   => '0500',
      source => 'puppet:///modules/profile/graphite/dhcp-to-graphite.py',
    }
    file { '/root/dhcpd-pool':
      ensure => file,
      mode   => '0500',
      source => 'puppet:///modules/profile/graphite/dhcpd-pool',
    }
    cron { 'send dhcp pools to graphite':
      ensure  => present,
      user    => 'root',
      command => 'cp /tmp/pool-output /tmp/pool-output.1; /root/dhcpd-pool | egrep "Subnet|Active" > /tmp/pool-output && /root/dhcp-to-graphite.py',
    }
  }

}
