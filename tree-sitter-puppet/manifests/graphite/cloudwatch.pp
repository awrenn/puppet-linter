class profile::graphite::cloudwatch {

  $access_key = hiera('profile::graphite::cloudwatch::access_key')
  $secret_key = hiera('profile::graphite::cloudwatch::secret_key')

  package { 'cloudwatch-to-graphite':
    ensure   => latest,
    provider => pip,
  }
  -> file { '/root/.aws':
    ensure => directory,
  }
  -> file { '/root/.aws/credentials':
    ensure  => file,
    mode    => '0400',
    content => template('profile/graphite/credentials.erb'),
  }
  -> file { '/root/ec2.yaml.j2':
    ensure => file,
    source => 'puppet:///modules/profile/graphite/ec2.yaml.j2',
  }
  -> file { '/root/rds.yaml.j2':
    ensure => file,
    source => 'puppet:///modules/profile/graphite/rds.yaml.j2',
  }
  -> file { '/root/gather_metrics.sh':
    ensure => file,
    mode   => '0744',
    source => 'puppet:///modules/profile/graphite/gather_metrics.sh',
  }
  -> cron { 'cloudwatch_to_graphite metrics':
    command => '/root/gather_metrics.sh',
    user    => root,
    minute  => '*/5',
  }

}
