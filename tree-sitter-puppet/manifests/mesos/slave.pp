# Class: profile::mesos::slave
#
class profile::mesos::slave (
  Boolean $include_java = false,
  String[1] $work_dir = '/home/mesos',
  String[1] $log_dir = '/var/log/mesos',
  Array $containerizers = ['docker', 'mesos'],
  Boolean $hyperthreading = true
) {

  include profile::mesos::common
  include profile::docker
  include profile::git
  include profile::mesos::slave::maintenance

  $checkpoint = hiera('profile::mesos::slave::checkpoint', true)
  meta_motd::register { 'Apache Mesos slave (profile::mesos::slave)': }

  if $profile::server::monitoring {
    include profile::mesos::slave::monitor
  }

  if $profile::server::fluentd {
    include profile::mesos::slave::fluentd
  }

  # firewalld is enabled by default on centos and causes trouble with mesos-slave
  service { 'firewalld':
    ensure => stopped,
    enable => false,
  }

  # Collect sweet metrics
  if $profile::server::metrics {
    include profile::metrics::diamond::collectors

    Diamond::Collector <| title == 'MesosCollector' |> {
      options      => {
        'measure_collector_time' => true,
        'host' => $hostname,
        'port' => 5051,
      }
    }
  }

  if $hyperthreading {
    $physical_cpus = $processors['count'] / 2
  } else {
    $physical_cpus = $processors['count']
  }

  # Clean up anything Mesos didn't.
  cron { 'mesos failsafe cleanup':
    command => "/usr/bin/find ${work_dir}/slaves/*/*/*/executors/ -mtime +8 -delete",
    hour    => 1,
  }

  cron { 'mesos log_dir failsafe cleanup':
    command => "/usr/bin/find ${log_dir} -type f -mtime +8 -delete",
    hour    => 1,
  }

  # Configure logrotate module
  # Following guidance of http://continuousfailure.com/post/mesos27_logging/
  file { '/etc/mesos/slave-modules.json':
    source => 'puppet:///modules/profile/mesos/slave-modules.json',
    mode   => '0664',
    owner  => 'root',
    group  => 'root',
  }

  # The deric/mesos Puppet module comments out the "LOGS" line in
  # /etc/default/mesos, which doesn't make a lot of sense. We can fix that
  # behavior by setting 'MESOS_LOG_DIR' here.
  class { '::mesos::slave':
    env_var        => {
      'MESOS_LOG_DIR' => $log_dir,
    },
    attributes     => {
      'hostname' => $fqdn,
    },
    checkpoint     => $checkpoint,
    listen_address => $network_primary_ip,
    work_dir       => $work_dir,
    options        => {
      'containerizers'                => join($containerizers, ','),
      'container_logger'              => 'org_apache_mesos_LogrotateContainerLogger',
      'executor_registration_timeout' => '8mins',
      'modules'                       => 'file:///etc/mesos/slave-modules.json',
    },
    resources      => {
      'cpus'  => $physical_cpus,
    },
    require        => Class['::docker'],
  }

  $staging_dir = '/usr/share/mesos/staging'
  file { $staging_dir: ensure => directory }

  $jobs = hiera('profile::mesos::slave::jobs', false)
  if $jobs {
    include $jobs
  }

  if $include_java {
    include java
  }

  profile_metadata::service { $title:
    human_name      => 'Mesos agent',
    team            => 'dio',
    end_users       => ['team-development-infrastructure-and-operations@puppet.com'],
    doc_urls        => [
      'https://confluence.puppetlabs.com/display/SRE/Mesos',
      'https://github.com/puppetlabs/cinext-docs/tree/master/infrastructure',
    ],
    downtime_impact => @(END),
      Mesos agents provide compute and memory for mesos. Work is distributed
      on the agents. At least one agent must be available for mesos frameworks
      to deploy work.
      | END
  }
}
