class profile::delivery::nightlies {
  file {
    '/usr/bin/purge_nightlies.rb':
      ensure => file,
      group  => 'root',
      mode   => '0700',
      source => 'puppet:///modules/profile/delivery/purge_nightlies.rb',
  }

  cron { 'purge_nightlies':
    ensure  => present,
    user    => 'root',
    command => '/usr/bin/purge_nightlies.rb',
    weekday => '*',
    hour    => 9,
    minute  => 0,
  }
}
