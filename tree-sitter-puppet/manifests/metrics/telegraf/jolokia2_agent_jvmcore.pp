# Collect core JVM metrics with Telegraf
class profile::metrics::telegraf::jolokia2_agent_jvmcore {
  $queries = [
    {
      'mbean' => 'java.lang:type=ClassLoading',
      'paths' => ['LoadedClassCount', 'TotalLoadedClassCount', 'UnloadedClassCount'],
      'name'  => 'java.lang.ClassLoading',
    },
    {
      'mbean'    => 'java.lang:type=GarbageCollector,*',
      'tag_keys' => ['name'],
      'paths'    => [
        'CollectionCount',
        'CollectionTime',
        'LastGcInfo',
      ],
      'name'     => 'java.lang.GarbageCollector',
    },
    {
      'mbean' => 'java.lang:type=Memory',
      'paths' => ['HeapMemoryUsage', 'NonHeapMemoryUsage'],
      'name'  => 'java.lang.Memory',
    },
    {
      'mbean' => 'java.lang:type=Runtime',
      'paths' => ['Uptime'],
      'name'  => 'java.lang.Runtime',
    },
    {
      'mbean' => 'java.lang:type=Threading',
      'paths' => ['ThreadCount', 'TotalStartedThreadCount', 'PeakThreadCount'],
      'name'  => 'java.lang.Threading',
    },
  ]

  $queries.each |$query| {
    telegraf::input { "jvmcore-${query['name']}":
      plugin_type => 'jolokia2_agent',
      options     => [{
        'urls'                 => ['https://localhost:8140/metrics/v2'],
        'insecure_skip_verify' => true,
        'metric'               => $queries,
      }],
    }
  }
}
