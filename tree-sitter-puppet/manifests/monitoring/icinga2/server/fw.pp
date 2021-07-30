class profile::monitoring::icinga2::server::fw {

  include profile::monitoring::icinga2::common

  if $::profile::monitoring::icinga2::common::parent_nodes != {} {
    $::profile::monitoring::icinga2::common::parent_nodes.each |$node, $f| {
      firewall { "300 allow icinga2 5665 for ${node} from ${f['ipaddress']}":
        proto  => 'tcp',
        action => 'accept',
        dport  => '5665',
        source => $f['ipaddress'],
      }
    }
  }
}
