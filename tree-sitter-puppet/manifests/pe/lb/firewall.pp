# Class: profile::pe::lb::firewall
#
# Configure iptables to allow all nodes to access services.
#
class profile::pe::lb::firewall {
  firewall {
    default:
      proto  => 'tcp',
      action => 'accept',
    ;
    '201 allow pe-console-80 from all':
      dport => 80,
    ;
    '201 allow pe-console-443 from all':
      dport => 443,
    ;
    '201 allow rbac-api from all':
      dport => 4433,
    ;
    '201 allow puppetdb-api from all':
      dport => 8081,
    ;
    '201 allow puppet-agent from all':
      dport => 8140,
    ;
    '201 allow pxp-agent from all':
      dport => 8142,
    ;
    '201 allow orchestrator-api from all':
      dport => 8143,
    ;
    '201 allow code-manager-api from all':
      dport => 8170,
    ;
    '201 allow stats-page from all':
      dport => 9000,
    ;
  }
}
