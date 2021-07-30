# Manage AWS nodes
class profile::pe::master::aws (
  String[1] $ec2_terminate_sqs_queue_name,
) {
  python::pip { 'boto3':
    ensure => present,
  }

  # remove code related to aws provisioning (DIO-1244)
  $sqs_queue_name = shellquote($ec2_terminate_sqs_queue_name)
  cron { 'purge-terminated-ec2-instances':
    ensure  => absent,
    command => "${puppetlabs::scripts::base}/deactivate_ec2_instances.py --sqs-queue-name ${sqs_queue_name} 2>&1 | logger -t ec2_terminate_instances",
    minute  => '*/5',
  }

  # remove old symlink used by the aws module (DIO-1244)
  file { '/etc/puppetlabs/puppet/puppetlabs_aws_credentials.ini':
    ensure => absent,
  }
}
