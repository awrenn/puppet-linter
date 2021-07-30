# send metrics to prometheus from haproxy via telegraf
class profile::artifactory::lb_metrics {
  telegraf::input { "${facts['networking']['fqdn']} load balancer metrics":
    plugin_type => 'haproxy',
    options     => [{
      servers => ['http://localhost:9000'],
    }],
  }
}

