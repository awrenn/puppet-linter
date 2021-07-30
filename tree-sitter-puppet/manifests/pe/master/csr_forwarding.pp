# Class: profile::pe::master::csr_forwarding
#
# Profile to manage classification settings specific to the test master
#
class profile::pe::master::csr_forwarding {

  # In test PE, we want to remove the "puppet_enterprise::profile::certificate_authority" class from the group below
  # Upgrades reverse this configuration, so we'll enforce it here.

  node_group { 'PE Certificate Authority':
    ensure      => present,
    environment => 'production',
    parent      => 'PE Infrastructure',
    rule        => ['or',
      ['=', 'name', $facts['networking']['fqdn']]
    ],
    classes     => {},
  }
}
