# Provide a class to manage yum-cron
class profile::os::linux::redhat::autoupdates (
  Boolean          $enabled             = true,
  Boolean          $skip_broken         = true,
  Integer[0]       $random_sleep        = 360,
  Integer[0, 23]   $update_hour         = 9,
  Integer[0, 59]   $update_minute       = 0,
  Integer[2, 4]    $debug_level         = 2,
  String           $log_file            = '/var/log/yum-cron.log',
  String           $config_file         = '/etc/yum/yum-cron-puppet.conf',
  Array[String[1]] $update_days         = ['Wednesday'],
  Array[String[1]] $additional_excludes = [],
  Enum['stdio', 'mail', 'None'] $output = 'stdio',
  Enum['default', 'security', 'security-severity:Critical', 'minimal', 'minimal-security', 'minimal-security-severity:Critical'] $update_cmd = 'default',
) {

  if $enabled {
    $ensure_autoupdates = present

    # When the yum-cron service is enabled it triggers default
    # yum-hourly and yum-daily jobs to run.
    # This implementation does not use yum-daily or yum-hourly.
    service { 'yum-cron':
      ensure  => stopped,
      require => Package['yum-cron'],
    }

    $excludes = profile::os::linux::autoupdates::get_exclusions('yum', $additional_excludes)
    if $excludes.length() > 0 {
      $package_exclude_list = "${excludes.join(' ')} ${facts['yumconf_exclude']}"
    }
  } else {
    $ensure_autoupdates = absent
  }

  package { 'yum-cron':
    ensure => $ensure_autoupdates,
  }

  file { $config_file:
    ensure  => $ensure_autoupdates,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/os/linux/redhat/yum-cron.conf.erb'),
    require => Package['yum-cron'],
  }

  cron { 'yum-cron_autoupdates':
    ensure  => $ensure_autoupdates,
    command => "/usr/sbin/yum-cron ${config_file} &>> ${log_file}",
    hour    => $update_hour,
    minute  => $update_minute,
    weekday => $update_days,
    require => Package['yum-cron'],
  }

  if ($profile::server::logging) and ($enabled) {
    include profile::logging::logstashforwarder

    logstashforwarder::file { 'unattended_upgrades':
      paths  => [ '/var/log/yum.log' ],
      fields => { 'type' => 'unattendedupgrades' },
    }
  }
}
