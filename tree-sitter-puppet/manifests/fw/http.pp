#
# Setup the firewall for an HTTP server
#
class profile::fw::http {

  include profile::fw

  firewall { '101 allow http':
    dport  => '80',
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '101 allow http v6':
    dport    => '80',
    proto    => 'tcp',
    action   => 'accept',
    provider => 'ip6tables',
  }
}
