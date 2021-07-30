# Setup fluentd to ship to fluentd aggregator
class profile::logging::fluentd(
  String[1] $output_aggregator_host  = 'fluentd-logs-test.k8s.infracore.puppet.net',
  Integer $output_aggregator_port    = 24224,
  Integer $forward_port              = 24224,
  String[1] $forward_bind            = '127.0.0.1',
  Integer $monitor_port              = 24220,
  String[1] $monitor_bind            = '0.0.0.0',
  Array[String[1]] $user_groups      = ['adm']
) {
  profile_metadata::service { $title:
    human_name        => 'fluentd United Logging Layer Agent',
    team              => dio,
    end_users         => [
      'infrastructure-user@puppet.com',
      'discuss-sre@puppet.com',
    ],
    escalation_period => '24x7',
    downtime_impact   => 'New logs are lost.',
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/HOW-TO+Use+the+DIO+Logging+Infrastructure',
    ],
  }

  $_svc_account = 'td-agent'

  User <| title == 'td-agent' |> ~> Service <| title == 'td-agent' |>

  class { 'fluentd':
    user_groups => $user_groups,
  }

  fluentd::source { 'forward':
    priority => 10,
    config   => {
      '@type' => 'forward',
      'port'  => $forward_port,
      'bind'  => $forward_bind,
    },
  }

  fluentd::source { 'monitor_agent':
    config => {
      '@type' => 'monitor_agent',
      'port'  => $monitor_port,
      'bind'  => $monitor_bind,
    },
  }

  fluentd::filter { 'add-hostname':
    priority => 20,
    pattern  => '**',
    config   => {
      '@type'  => 'record_transformer',
      'record' => {
        'host' => "${facts['networking']['fqdn']}",
      },
    },
  }

  fluentd::match { 'all':
    pattern => '**',
    config  => {
      '@type'     => 'forward',
      'server'    => {
        'name' => 'aggregator',
        'host' => $output_aggregator_host,
        'port' => $output_aggregator_port,
      },
      'secondary' => {
        '@type' => 'file',
        'path'  => '/var/log/td-agent/forward-failed',
      },
    },
  }
}
