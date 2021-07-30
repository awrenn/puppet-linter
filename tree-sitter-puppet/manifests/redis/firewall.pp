class profile::redis::firewall {
  firewall { '102 allow redis port 6379':
    proto  => 'tcp',
    action => 'accept',
    dport  => '6379',
  }
}
