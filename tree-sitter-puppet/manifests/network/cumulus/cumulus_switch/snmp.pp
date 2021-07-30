class profile::network::cumulus::cumulus_switch::snmp (
  $config  = {},
){
  # Cumulus SNMP Configuration
  service {'snmpd':
    ensure =>  'running',
    enable =>  true,
  }

  file_line {'snmp add snmp plops community':
    ensure => present,
    path   => '/etc/snmp/snmpd.conf',
    line   => 'rocommunity plops default -V systemonly',
    notify => Service['snmpd'],
  }

  file_line {'snmp listen on all ports':
    ensure => present,
    path   => '/etc/snmp/snmpd.conf',
    line   => 'agentAddress udp:161,udp6:[::1]:161',
    notify => Service['snmpd'],
    match  => '^agentAddress',
  }
}
