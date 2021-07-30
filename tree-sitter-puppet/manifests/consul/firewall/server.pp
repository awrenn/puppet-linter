# Firewall rules for Consul Servers
class profile::consul::firewall::server {
  include haproxy_consul::dns_on_53

  firewall {
    default:
      action => 'accept',
    ;
    '102 allow global access to consul server port 8500 for HTTP API':
      proto => 'tcp',
      dport => 8500,
    ;
    '102 allow global access to consul port 8600 TCP for DNS':
      dport => 8600,
      proto => 'tcp',
    ;
    '102 allow global access to consul port 8600 UDP for DNS':
      dport => 8600,
      proto => 'udp',
    ;
    '103 allow global for port 8300 for agent connectivity':
      proto => 'tcp',
      dport => 8300,
    ;
  }

  $consul_server_ips = (puppetdb_query("inventory {
    facts.classification.stage = '${facts['classification']['stage']}' and
    resources {
      type = 'Class' and
      title = 'Role::Consul::Server'
    }
  }").map |$value| { $value['facts']['networking']['ip'] }).unique

  each(unique($consul_server_ips)) |$node_ipaddress| {
    firewall {
      default:
        proto  => 'tcp',
        action => 'accept',
        source => $node_ipaddress,
      ;
      "104 allow ${node_ipaddress} consul server port 8302 TCP for Serf WAN":
        dport => 8302,
      ;
      "104 allow ${node_ipaddress} consul server port 8302 UDP for Serf WAN":
        dport => 8302,
        proto => 'udp',
      ;
    }
  }
}
