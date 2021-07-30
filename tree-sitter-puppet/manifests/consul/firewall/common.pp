class profile::consul::firewall::common {
  firewall {
    default:
      action => 'accept',
      dport  => 8301,
    ;
    '102 allow global access to consul server port 8301 TCP for Serf LAN':
      proto => 'tcp',
    ;
    '102 allow global access to consul server port 8301 UDP for Serf LAN':
      proto => 'udp',
    ;
  }

  each($profile::consul::servers) |$node_ipaddress| {
    firewall {
      default:
        proto  => 'tcp',
        action => 'accept',
        source => $node_ipaddress,
      ;
      "102 allow ${node_ipaddress} consul server port 8400 for RPC":
        dport   => 8400,
      ;
      "102 allow ${node_ipaddress} consul serverport 8300 for server RPC":
        dport   => 8300,
      ;
    }
  }
}
