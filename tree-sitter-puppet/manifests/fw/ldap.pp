#
# Setup the firewall for the LDAP servers
#
class profile::fw::ldap {

  include profile::fw

  firewall { '100 allow ldap':
    dport  => '389',
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '101 allow ldaps':
    dport  => '636',
    proto  => 'tcp',
    action => 'accept',
  }
}
