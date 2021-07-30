# Configures metrics collection for Confluence.
class profile::confluence::app::metrics {
  # include profile::metrics::jmxtrans

  # profile::metrics::jmxtrans::jvmcore { 'confluence':
  #   host => $facts['networking']['fqdn'],
  #   port => $confluence::jmx_port,
  # }

  # # These metrics are found under the "Standalone" object, not "Catalina"
  # profile::metrics::jmxtrans::catalina { 'confluence':
  #   host                 => $facts['networking']['fqdn'],
  #   port                 => $confluence::jmx_port,
  #   catalina_object_name => 'Standalone',
  # }

  # above should be replaced with something like
  # site/profile/manifests/metrics/telegraf/jolokia2_agent_jvmcore.pp
  # and/or the app-specific bits from
  # site/profile/manifests/pe/master_common/metrics.pp
}
