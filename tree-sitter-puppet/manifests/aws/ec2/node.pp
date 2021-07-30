# Configure a node running in AWS. The node must be provisioned following the
# pattern in profile::aws::ec2::instances3 (no such profile exists post DIO-1244)
#
# Pass $dns => false to disable setting DNS records.
class profile::aws::ec2::node (
  Boolean $dns = true,
) {
  include profile::aws::common

  if $dns {
    include profile::aws::ec2::node::dns
  }

  file { '/etc/cloud/cloud.cfg.d/50_puppet.cfg':
    ensure  => file,
    owner   => 'root',
    group   => '0',
    mode    => '0444',
    content => @(50_PUPPET.CFG),
      preserve_hostname: true
      manage_etc_hosts: false
      |50_PUPPET.CFG
  }
}
