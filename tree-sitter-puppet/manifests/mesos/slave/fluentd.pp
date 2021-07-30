class profile::mesos::slave::fluentd {
  fluentd::plugin { 'fluent-plugin-mesosphere-filter':
    type   => 'gem',
    ensure => '0.2.0',
  }

  # Docker group is necessary for access to container metadata from docker socket, added to user_groups array via Hiera
  realize(Group['docker'])

  fluentd::filter { 'docker-mesosphere':
    pattern => 'docker.*',
    config  => {
      '@type'          => 'mesosphere_filter',
      'merge_json_log' => true,
    },
  }
}
