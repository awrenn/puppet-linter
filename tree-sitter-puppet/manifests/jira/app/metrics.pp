# Configures metrics collection for JIRA.
class profile::jira::app::metrics {
  # include profile::metrics::jmxtrans

  # profile::metrics::jmxtrans::jvmcore { 'jira':
  #   host => $facts['networking']['fqdn'],
  #   port => $jira::jmx_port,
  # }

  # profile::metrics::jmxtrans::catalina { 'jira':
  #   host => $facts['networking']['fqdn'],
  #   port => $jira::jmx_port,
  # }

  # above should be replaced with something like
  # site/profile/manifests/metrics/telegraf/jolokia2_agent_jvmcore.pp
  # and/or the app-specific bits from
  # site/profile/manifests/pe/master_common/metrics.pp
}
