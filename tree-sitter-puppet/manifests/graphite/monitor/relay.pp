class profile::graphite::monitor::relay inherits ::profile::monitoring::icinga2::common {

  include profile::graphite::common

  # cache_instances is every instance of carbon-cache except the first one, 'a' - so we
  # add 'a' to the cache instance map, and split and join over the name, giving us an array
  # that looks like [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p]

  $cache_array = ['a'] + $::profile::graphite::common::cache_instances.map |$cache_name, $cache_value| {
    split($cache_name,':')[1]
  }

  # We want to make sure each instance is monitored, as each instance handles a subset of metrics
  if $graphite::gr_enable_carbon_cache {
    $cache_array.each |$instance| {
      icinga2::object::service { "check-carbon-cache-${instance}":
        check_command => 'procs',
        vars          => {
          'procs_critical' => '1:1',
          'procs_argument' => "carbon-cache.py --instance=${instance} start",
          'procs_warning'  => '1:',
        },
      }
    }
  }

  # 1 instance of carbon-relay should be running
  icinga2::object::service { 'carbon-relay':
    check_command => 'procs',
    vars          => {
      'procs_critical' => '1:1',
      'procs_argument' => 'carbon-relay.py --instance=a start',
      'procs_warning'  => '1:',
    },
  }
}
