# send metrics to puppet_metrics_dashboard
class profile::pe::lb::metrics {
  telegraf::input { "${facts['networking']['fqdn']} load balancer metrics":
    plugin_type => 'haproxy',
    options     => [{
      servers => ['http://localhost:9000'],
    }],
  }
}
