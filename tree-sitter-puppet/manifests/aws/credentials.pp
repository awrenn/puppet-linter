# Class: profile::aws::credentials
#
# configure AWS credentials
# the reason this isn't done by default on all nodes with AWS tools is that
# nodes in EC2 don't need it -- they can (and should) use IAM roles to get
# access to AWS resources without access keys.
#
class profile::aws::credentials (
  $access_key_id = undef,
  $secret_access_key = undef,
  $region = 'us-west-2',
){
  file { '/root/.aws':
    ensure => directory,
    mode   => '0700',
  }

  file { '/root/.aws/credentials':
    ensure  => present,
    mode    => '0400',
    content =>  template('profile/aws/credentials.erb'),
    require => File['/root/.aws'],
  }
}
