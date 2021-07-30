# Class: profile::mesos::master
#
class profile::mesos::master (
  String[1] $cluster = 'mesos',
  String[1] $log_dir = '/var/log/mesos',
  $options = undef
){
  include profile::mesos::common

  if $::profile::server::params::monitoring {
    include profile::mesos::master::monitor
  }

  meta_motd::register { 'Apache Mesos master (profile::mesos::master)': }

  # Collect sweet metrics
  if $::profile::server::metrics {
    include profile::metrics::diamond::collectors

    Diamond::Collector <| title == 'MesosCollector' |> {
      options      => {
        'measure_collector_time' => true,
        'host' => $hostname,
      }
    }
  }

  cron { 'mesos log_dir failsafe cleanup':
    command => "/usr/bin/find ${log_dir} -type f -mtime +8 -delete",
    hour    => 1,
  }

  # The deric/mesos Puppet module comments out the "LOGS" line in
  # /etc/default/mesos, which doesn't make a lot of sense. We can fix that
  # behavior by setting 'MESOS_LOG_DIR' here.
  class { '::mesos::master':
    env_var => {
      'MESOS_LOG_DIR' => $log_dir,
    },
    options => $options,
    cluster => $cluster,
  }

  profile_metadata::service { $title:
    human_name      => 'Mesos master',
    team            => 'dio',
    end_users       => ['team-development-infrastructure-and-operations@puppet.com'],
    doc_urls        => [
      'https://confluence.puppetlabs.com/display/SRE/Mesos',
      'https://github.com/puppetlabs/cinext-docs/tree/master/infrastructure',
    ],
    downtime_impact => @(END),
      Mesos masters coordinate workload distribution and run frameworks to interact
      with external data sources like jenkins. If a single mesos master goes down,
      and the node is not the cluster leader, then there is no functional impact. If
      the leading master goes down a new master will be elected. If all masters are down
      then mesos will stop scheduling work.
      | END
  }
}
