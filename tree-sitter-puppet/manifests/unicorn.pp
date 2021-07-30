# Common needs for profile::unicorn::app instances.
class profile::unicorn {
  $config_dir = '/etc/unicorn'

  file { $config_dir:
    ensure => directory,
    mode   => '0755',
    owner  => 'root',
    group  => '0',
  }
}
