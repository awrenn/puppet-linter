class profile::docker::metrics (
  $docker_py_version = '1.10.6',
  $telegraf_docker_labes_include = [ 'server_version' ],
) {
  # telegraf settings defined in hiera to avoid duplicate resource declaration
  include profile::metrics::diamond::collectors

  python::pip { 'docker-py':
    ensure => $docker_py_version,
  }

  Diamond::Collector <| title == 'DockerCollector' |> {
    options => {
      'measure_collector_time' => true,
      'host'                   => $hostname,
      'port'                   => 5051,
    }
  }


  if $profile::metrics::enable_prometheus {
    include profile::metrics::telegraf::client

    telegraf::input { 'docker':
      plugin_type => 'docker',
      options     => [{
        'gather_services'      => true,
        'endpoint'             => 'unix:///var/run/docker.sock',
        'docker_label_exclude' => ['*'],
        'docker_label_include' => $telegraf_docker_labes_include,
      }],
    }
  }

}
