# Class: profile::pe::master_common::metrics
#
# Configures metrics collection for PE master services.
#
class profile::pe::master_common::metrics (
  $graphite_host = 'graphite.ops.puppetlabs.net'
) {
  include profile::metrics::telegraf::jolokia2_agent_jvmcore

  $count = ['Count']
  $value = ['Value']
  $histo = ['Max', 'Min', 'Mean', 'StdDev', 'Count', '50thPercentile', '75thPercentile', '95thPercentile', '99thPercentile']

  $attributes = {
    'compiler.create_settings_scope'     => $histo,
    'compiler.evaluate_ast_node'         => $histo,
    'compiler.evaluate_main'             => $histo,
    'compiler.evaluate_node_classes'     => $histo,
    'compiler.evaluate_definitions'      => $histo,
    'compiler.evaluate_generators'       => $histo,
    'compiler.finish_catalog'            => $histo,
    'compiler.set_node_params'           => $histo,
    'compiler.static_compile'            => $histo,
    'compiler.static_compile.production' => $histo,
    'http.active-requests'               => $count,
    'http.active-histo'                  => $histo,
    'http.total-requests'                => $histo,
    'jruby.borrow-count'                 => $count,
    'jruby.borrow-retry-count'           => $count,
    'jruby.borrow-timeout-count'         => $count,
    'jruby.borrow-timer'                 => $histo,
    'jruby.free-jrubies-histo'           => $histo,
    'jruby.num-free-jrubies'             => $value,
    'jruby.num-jrubies'                  => $value,
    'jruby.request-count'                => $count,
    'jruby.requested-jrubies-histo'      => $histo,
    'jruby.return-count'                 => $count,
    'jruby.wait-timer'                   => $histo,
  }

  $queries = $attributes.reduce([]) |$memo, $val| {
    $obj_name = $val[0]
    $obj_attr = $val[1]
    $memo + [{
      'name'  => "puppetlabs.${obj_name}",
      'mbean' => "puppetserver:name=puppetlabs.${facts['networking']['hostname']}.${obj_name}",
      'paths' => $obj_attr,
    }]
  }

  telegraf::input { 'puppetserver-jmx':
    plugin_type => 'jolokia2_agent',
    options     => [{
      'urls'                 => ['https://localhost:8140/metrics/v2'],
      'tls_ca'               => '/etc/telegraf/ca.pem',
      'tls_cert'             => "/etc/telegraf/${facts['networking']['fqdn']}_cert.pem",
      'tls_key'              => "/etc/telegraf/${facts['networking']['fqdn']}_key.pem",
      'insecure_skip_verify' => true,
      'metric'               => $queries,
    }],
  }

  puppet_metrics_dashboard::profile::compiler{ $facts['networking']['fqdn']:
    timeout => '25s',
  }

  puppet_metrics_dashboard::profile::puppetdb{ $facts['networking']['fqdn']:
    timeout            => '25s',
    enable_client_cert => false,
  }
}
