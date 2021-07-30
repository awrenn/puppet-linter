# Configure garbage collection for docker
class profile::docker::garbage_collection {

  include profile::internal_tools_repo

  package { 'docker-gc':
    ensure  => present,
    require => Class['Profile::Internal_tools_repo'],
  }

  # exclude all images.  only do garbage collection on exited containers.
  file { '/etc/docker-gc-exclude':
    ensure  => present,
    content => '*',
  }

  # run hourly, log to syslog, and only garbage collect containers after they have aged 30 minutes.
  cron { 'run docker-gc hourly':
    ensure  => present,
    command => 'LOG_TO_SYSLOG=1 GRACE_PERIOD_SECONDS=1800 /usr/sbin/docker-gc',
    hour    => '*',
    minute  => 0,
  }
}
