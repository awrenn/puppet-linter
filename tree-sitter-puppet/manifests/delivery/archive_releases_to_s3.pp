class profile::delivery::archive_releases_to_s3 {
  include s3cmd

  file { '/usr/local/bin/archive_releases_to_s3':
    ensure => 'file',
    source => 'puppet:///modules/profile/delivery/archive_releases_to_s3',
    owner  => 'root',
    mode   => '0755',
  }

  # stop this while we rethink archives
  # https://tickets.puppetlabs.com/browse/RE-11595
  cron { 'archive_releases_to_s3':
    ensure  => absent,
    command => '/usr/local/bin/archive_releases_to_s3 > /tmp/arts3.out 2>&1',
    user    => 'root',
    hour    => 6,
    minute  => 0,
    weekday => 'Monday',
  }
}
