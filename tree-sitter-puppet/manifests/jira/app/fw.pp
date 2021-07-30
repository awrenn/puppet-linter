##This allows the option to block GitHub traffic.
##Used on our test instances to avoid GitHub API rate limiting.

class profile::jira::app::fw (
  Boolean $enable = false
) {
  if $enable {
    firewall { '100 drop github inbound':
      action    => 'reject',
      src_range => '192.30.252.0-192.30.255.255',
    }
    firewall { '101 drop github outbound':
      chain     => 'OUTPUT',
      action    => 'reject',
      dst_range => '192.30.252.0-192.30.255.255',
    }
  }
}
