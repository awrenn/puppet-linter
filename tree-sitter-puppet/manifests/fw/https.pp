#
# Setup the firewall for an HTTPS server
#
class profile::fw::https {

  include profile::fw

  firewall { '102 allow https':
    dport  => '443',
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '102 allow https v6':
    dport    => '443',
    proto    => 'tcp',
    action   => 'accept',
    provider => 'ip6tables',
  }

  firewall { '103 allow http':
    dport  => '80',
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '103 allow http v6':
    dport    => '80',
    proto    => 'tcp',
    action   => 'accept',
    provider => 'ip6tables',
  }
}
