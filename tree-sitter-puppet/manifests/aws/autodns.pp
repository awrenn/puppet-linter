class profile::aws::autodns (
  $ttl = 300
){
  include profile::aws::common

  # This profile used to also create records in route53. We are no longer
  # managing AWS via Puppet. route53 entries should now be managed via
  # your provisioning process. Please also note that the puppetlabs/puppetlabs-aws
  # repo for the module we used for this is now archived too.

  if $facts['networking']['domain'] == 'ops.puppetlabs.net' {
    @@dns_record { $facts['networking']['fqdn']:
      ensure  => present,
      domain  => 'ops.puppetlabs.net',
      content => $facts['networking']['ip'],
      type    => 'A',
      ttl     => $ttl,
    }
  }
}

