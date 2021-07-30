# Configuration for all EC2 nodes
class profile::aws::common (
  $region = 'us-west-2',
){
  # Needed for puppetlabs-aws module
  package { 'aws-sdk-core':
    ensure   => '2.9.34',
    provider => 'puppet_gem',
  }

  package { 'retries':
    ensure   => present,
    provider => 'puppet_gem',
  }
}
