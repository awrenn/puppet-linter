# Add SNMP monitoring for infra managed/monitored by IT SysOps
#
class profile::network::snmp {
  $package_name = $facts['os']['family'] ? {
    'Debian' => 'snmpd',
    'RedHat' => 'net-snmp',
  }

  package { $package_name:
    ensure => present,
  }

  file {'/etc/snmp/snmpd.conf':
    ensure  => file,
    content => epp('profile/network/snmpd.conf.epp'),
    require => Package[$package_name],
    notify  => Service['snmpd'],
  }

  service { 'snmpd':
    ensure => running,
  }

  firewall { "000 accept prtg snmp ${facts['networking']['primary']}":
    proto   => 'udp',
    source  => '10.64.4.42/32',
    dport   => '161',
    iniface => $facts['networking']['primary'],
    action  => 'accept',
  }
}
