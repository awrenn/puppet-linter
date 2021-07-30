# Class: profile::pe::compiler::firewall
#
# Configures iptables to allow the load balancer to connect on 8140.
#
class profile::pe::compiler::firewall {
  $lbs = puppetdb_query("inventory {
    facts.classification.stage = '${facts['classification']['stage']}' and
    facts.classification.context = '${facts['classification']['context']}' and
    resources {
      type = 'Class' and
      title = 'Role::Pe::Lb'
    }
  }")

  $lbs.each |$node| {
    $n_name = $node['facts']['networking']['fqdn']
    $n_ip   = $node['facts']['networking']['ip']
    firewall {
      default:
        proto  => 'tcp',
        action => 'accept',
        source => $n_ip,
      ;
      "201 allow puppetdb-api from ${n_name} via ${n_ip}":
        dport => 8081,
      ;
      "201 allow puppet-agent from ${n_name} via ${n_ip}":
        dport => 8140,
      ;
      "201 allow pxp-agent from ${n_name} via ${n_ip}":
        dport => 8142,
      ;
    }
  }

  $master = puppetdb_query("inventory {
    resources {
      type = 'Class' and
      title = 'Role::Pe::Master'
    }
  }")

  ($master).each |$node| {
    $n_name = $node['facts']['networking']['fqdn']
    $n_ip   = $node['facts']['networking']['ip']
    firewall { "201 allow puppet-agent from ${n_name} via ${n_ip}":
      proto  => 'tcp',
      action => 'accept',
      source => $n_ip,
      dport  => 8140,
    }
    firewall { "201 allow puppetdb from ${n_name} via ${n_ip}":
      proto  => 'tcp',
      action => 'accept',
      source => $n_ip,
      dport  => 8081,
    }
  }
}
