class profile::delivery::cleanup_opt_repos {
  include s3cmd

  file { '/usr/local/bin/cleanup-opt-repos':
    ensure => 'file',
    source => 'puppet:///modules/profile/delivery/cleanup-opt-repos',
    owner  => 'root',
    mode   => '0755',
  }

  # Run cleanup every Tuesday.
  # Logs are kept in /var/log/weth-cleanup-script
  # pause this while we rethink archiving
  # https://tickets.puppetlabs.com/browse/RE-11595
  cron { 'cleanup-opt-repos':
    ensure  => absent,
    command => '/usr/local/bin/cleanup-opt-repos > /tmp/cor.out 2>&1',
    user    => 'root',
    hour    => 6,
    minute  => 0,
    weekday => 'Tuesday',
  }
}
