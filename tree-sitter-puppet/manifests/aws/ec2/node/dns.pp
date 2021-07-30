# Configure DNS for an EC2 node. The node must be provisioned following the
# pattern in profile::aws::ec2::instances3. (no such profile exists post DIO-1244)

# This profile used to also create records in route53. We are no longer
# managing AWS via Puppet. route53 entries should now be managed via
# your provisioning process. Please also note that the puppetlabs/puppetlabs-aws
# repo for the module we used for this is now archived too.
class profile::aws::ec2::node::dns (
  Integer[1] $ops_ttl = 300,
) {
  if $trusted['domain'] != 'certs.puppet.net' {
    fail('profile::aws::ec2::node::dns requires cert domain certs.puppet.net')
  }

  if $facts['networking']['domain'] != 'ops.puppetlabs.net' {
    fail('profile::aws::ec2::node::dns requires domain ops.puppetlabs.net')
  }

  @@dns_record { "${facts['networking']['fqdn']}.":
    ensure  => present,
    domain  => 'ops.puppetlabs.net',
    type    => 'A',
    ttl     => $ops_ttl,
    content => $facts['networking']['ip'],
  }
}
