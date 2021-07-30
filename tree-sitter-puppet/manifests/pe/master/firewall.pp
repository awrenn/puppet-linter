# Class: profile::pe::master::firewall
#
# This opens all the ports required for proper operation of the master and related services.
#
class profile::pe::master::firewall {
  $pe_lbs = puppetdb_query("inventory {
    facts.classification.stage = '${facts['classification']['stage']}' and
    facts.classification.context = '${facts['classification']['context']}' and
    resources {
      type = 'Class' and
      title = 'Role::Pe::Lb'
    }
  }")

  $pe_lbs.each |$node| {
    $n_name = $node['facts']['networking']['fqdn']
    $n_ip   = $node['facts']['networking']['ip']
    firewall {
      default:
        proto  => 'tcp',
        action => 'accept',
        source => $n_ip,
      ;
      "201 allow pe-console-80 from ${n_name} via ${n_ip}":
        dport => 80,
      ;
      "201 allow pe-console-443 from ${n_name} via ${n_ip}":
        dport => 443,
      ;
      "201 allow rbac-api from ${n_name} via ${n_ip}":
        dport => 4433,
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
      "201 allow orchestrator-api from ${n_name} via ${n_ip}":
        dport => 8143,
      ;
      "201 allow code-manager-api from ${n_name} via ${n_ip}":
        dport => 8170,
      ;
      "201 allow stats-page from ${n_name} via ${n_ip}":
        dport => 9000,
      ;
    }
  }

  $compilers = puppetdb_query("inventory {
    facts.classification.stage = '${facts['classification']['stage']}' and
    facts.classification.context = '${facts['classification']['context']}' and
    resources {
      type = 'Class' and
      title = 'Role::Pe::Compiler'
    }
  }")

  $compilers.each |$node| {
    $n_name = $node['facts']['networking']['fqdn']
    $n_ip   = $node['facts']['networking']['ip']
    firewall {
      default:
        proto  => 'tcp',
        action => 'accept',
        source => $n_ip,
      ;
      "201 allow rbac-api from ${n_name} via ${n_ip}":
        dport => 4433,
      ;
      "201 allow pe console reports 4435 from ${n_name} via ${n_ip}":
        dport  => 4435,
      ;
      "201 allow postgresql from ${n_name} via ${n_ip}":
        dport  => 5432,
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
      "201 allow orchestrator-api from ${n_name} via ${n_ip}":
        dport => 8143,
      ;
    }
  }

  $pe_cd4pe = puppetdb_query("inventory {
    facts.classification.stage = '${facts['classification']['stage']}' and
    facts.classification.context = '${facts['classification']['context']}' and
    resources {
      type = 'Class' and
      title = 'Cd4pe'
    }
  }")

  $pe_cd4pe.each |$node| {
    $n_name = $node['facts']['networking']['fqdn']
    $n_ip   = $node['facts']['networking']['ip']
    firewall {
      default:
        proto  => 'tcp',
        action => 'accept',
        source => $n_ip,
      ;
      "201 allow code-manager-api from ${n_name} via ${n_ip}":
        dport => 8170,
      ;
      "201 allow pe-console-api from ${n_name} via ${n_ip}":
        dport => 4433,
      ;
      "201 allow pe-puppetserver-api from ${n_name} via ${n_ip}":
        dport => 8140,
      ;
      "201 allow pe-puppetdb-api from ${n_name} via ${n_ip}":
        dport => 8081,
      ;
      "201 allow pxp-agent from ${n_name} via ${n_ip}":
        dport => 8142,
      ;
      "201 allow pe-orchestrator-api from ${n_name} via ${n_ip}":
        dport => 8143,
      ;
    }
  }

  $pe_cd4pe_worker = puppetdb_query("inventory {
    facts.classification.stage = '${facts['classification']['stage']}' and
    resources {
      type = 'Class' and
      title = 'Role::Pe::Cd4peworker'
    }
  }")

  $pe_cd4pe_worker.each |$node| {
    $n_name = $node['facts']['networking']['fqdn']
    $n_ip   = $node['facts']['networking']['ip']
    firewall {
      default:
        proto  => 'tcp',
        action => 'accept',
        source => $n_ip,
      ;
      "201 allow pe-puppetserver-api from ${n_name} via ${n_ip}":
        dport => 8140,
      ;
      "201 allow pxp-agent from ${n_name} via ${n_ip}":
        dport => 8142,
      ;
    }
  }

  $pe_comply = puppetdb_query("inventory {
    resources {
      type = 'Class' and
      title = 'Role::Pe::Comply'
    }
  }")

  $pe_comply.each |$node| {
    $n_name = $node['facts']['networking']['fqdn']
    $n_ip   = $node['facts']['networking']['ip']
    firewall {
      default:
        proto  => 'tcp',
        action => 'accept',
        source => $n_ip,
      ;
      "201 allow pe-puppetserver-api from ${n_name} via ${n_ip}":
        dport => 8140,
      ;
      "201 allow pxp-agent from ${n_name} via ${n_ip}":
        dport => 8142,
      ;
    }
  }
}
