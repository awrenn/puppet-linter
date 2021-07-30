class profile::metrics::diamond::collectors {

  # Collector configs are documented here:
  # https://github.com/BrightcoveOS/Diamond/wiki/Collectors

  # Collectors go here
  # Realize them in your profiles. Override the options param.

  @diamond::collector { 'NginxCollector': }
  @diamond::collector { 'HAProxyCollector': }
  @diamond::collector { 'ElasticSearchCollector': }

  # Section for default collectors
  @diamond::collector { 'PuppetAgentCollector':
    options =>  {
      'yaml_path' => '/opt/puppetlabs/puppet/cache/state/last_run_summary.yaml',
    },
    tag     => ['default'],
    require => Python::Pip['pyyaml'],
  }
  @diamond::collector { 'EntropyStatCollector':
    tag => ['default'],
    }
  @diamond::collector { 'NetworkCollector':
    tag => ['default'],
    }
  @diamond::collector { 'TCPCollector':
    tag => ['default'],
    }
  @diamond::collector { 'NtpdCollector':
    tag => ['default'],
  }
  @diamond::collector { 'MemoryCollector':
    tag => ['default'],
  }
  @diamond::collector { 'CPUCollector':
    tag => ['default'],
  }
  @diamond::collector { 'DiskSpaceCollector':
    tag => ['default'],
  }
  @diamond::collector { 'LoadAverageCollector':
    tag => ['default'],
  }
  @diamond::collector { 'VMStatCollector':
    tag => ['default'],
  }
  @diamond::collector { 'DiskUsageCollector':
    tag => ['default'],
  }
  @diamond::collector { 'MesosCollector': }
  @diamond::collector { 'DockerCollector': }
}
