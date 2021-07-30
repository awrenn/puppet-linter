class profile::zookeeper::firewall {
  $clients = unique(puppetdb_query("inventory {
    facts.classification.group = '${facts['classification']['group']}' and
    facts.classification.stage = '${facts['classification']['stage']}'
  }").map |$value| { $value['facts']['networking']['ip'] })

  each($clients) |$client_ipaddress| {
    firewall { "102 allow ${client_ipaddress} zookeeper port 2181":
      proto  => 'tcp',
      action => 'accept',
      dport  => 2181,
      source => $client_ipaddress,
    }
  }

  $zookeeper_nodes = unique(puppetdb_query("inventory {
    facts.classification.group    = '${facts['classification']['group']}' and
    facts.classification.stage    = '${facts['classification']['stage']}' and
    facts.classification.function = '${facts['classification']['function']}'
  }").map |$value| { $value['facts']['networking']['ip'] })

  each($zookeeper_nodes) |$zk_ipaddress| {
    firewall { "102 allow ${zk_ipaddress} zookeeper nodes port 3888":
      proto  => 'tcp',
      action => 'accept',
      dport  => 3888,
      source => $zk_ipaddress,
    }

    firewall { "102 allow ${zk_ipaddress} zookeper nodes port 2888":
      proto  => 'tcp',
      action => 'accept',
      dport  => 2888,
      source => $zk_ipaddress,
    }
  }
}
