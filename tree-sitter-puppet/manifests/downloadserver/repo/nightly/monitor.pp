class profile::downloadserver::repo::nightly::monitor
    inherits ::profile::monitoring::icinga2::common {
  $nightly_base = $::profile::downloadserver::repo::nightly::nightly_base
  $escalate_projects = ['puppet-agent', 'puppetserver']
  $noescalate_projects = ['puppetdb']

  $escalate_projects.each |$project| {
    icinga2::object::service { "${project}-directory-freshness":
      check_command      => 'directory-freshness',
      display_name       => "${project} nightlies freshness",
      check_interval     => '1h',
      retry_interval     => '5m',
      max_check_attempts => 2,
      vars               => {
        directory             => "${nightly_base}/${project}",
        verbose               => true,
        warning               => '21',
        critical              => '28',
        escalate              => true,
        exclude               => ['latest'],
        notification_period   => 'workhours',
        notification_interval => '86400',
      },
    }
  }

  $noescalate_projects.each |$project| {
    icinga2::object::service { "${project}-directory-freshness":
      check_command      => 'directory-freshness',
      display_name       => "${project} nightlies freshness",
      check_interval     => '1h',
      retry_interval     => '5m',
      max_check_attempts => 2,
      vars               => {
        directory             => "${nightly_base}/${project}",
        verbose               => true,
        warning               => '21',
        critical              => '28',
        exclude               => ['latest'],
        notification_period   => 'workhours',
        notification_interval => '86400',
      },
    }
  }
}
