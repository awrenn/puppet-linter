class profile::fw {
  class { '::firewall': }
  -> class { ['::profile::fw::pre', '::profile::fw::post']: }

  Firewall {
    before  => Class['::profile::fw::post'],
    require => Class['::profile::fw::pre'],
  }
}
