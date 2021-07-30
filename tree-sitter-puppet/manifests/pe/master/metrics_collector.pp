class profile::pe::master::metrics_collector {

  $puppetserver_hosts = puppetdb_query(@(PQL)).map |$r| { $r['certname'] }
    inventory[certname] {
      resources {
        type = "Class"
        and title = "Puppet_enterprise::Profile::Master"
      }
      and nodes { deactivated is null and expired is null }
    }
    |-PQL

  # Schedule the tidying for well after the PuppetDB dump runs.
  class { 'puppet_metrics_collector':
    puppetserver_hosts => $puppetserver_hosts,
    retention_days     => 30,
  }

  # clean up from pe_metric_curl_cron_jobs
  $pe_metric_curl_cron_jobs = [
    'pe_metric_curl_cron_jobs: orchestrator_metrics_collection',
    'pe_metric_curl_cron_jobs: orchestrator_metrics_tidy',
    'pe_metric_curl_cron_jobs: puppetdb_metrics_collection',
    'pe_metric_curl_cron_jobs: puppetdb_metrics_tidy',
    'pe_metric_curl_cron_jobs: puppetserver_metrics_collection',
    'pe_metric_curl_cron_jobs: puppetserver_metrics_tidy',
  ]

  cron { $pe_metric_curl_cron_jobs:
    ensure => absent,
  }
}
