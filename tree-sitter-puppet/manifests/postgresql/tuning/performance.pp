class profile::postgresql::tuning::performance {

  $shared_buffers       = '512MB'  # 1/4 Ram
  $effective_cache_size = '1024MB' # 1/2 Ram
  $work_mem             = '8MB'
  $maintenance_work_mem = '64MB'

  postgresql::server::config_entry { 'shared_buffers':
    value => $shared_buffers,
  }

  postgresql::server::config_entry { 'effective_cache_size':
    value => $effective_cache_size,
  }

  postgresql::server::config_entry { 'work_mem':
    value => $work_mem,
  }

  postgresql::server::config_entry { 'maintenance_work_mem':
    value => $maintenance_work_mem,
  }
}
