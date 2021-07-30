class profile::zookeeper::metrics {

  Diamond::Collector <| title == 'ZookeeperCollector' |> {
    options      => {
      'measure_collector_time' => true,
      'hosts' => [$hostname,],
    }
  }
}
