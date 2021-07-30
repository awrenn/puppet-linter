# Export graphite metrics to prometheus
class profile::graphite::prometheus_exporter (
  String[1] $version = '0.6.2',
) {
  realize(Account::User['graphite-exporter'])

  file{
    default:
      owner   => 'graphite-exporter',
      group   => 'graphite-exporter',
      require => Account::User['graphite-exporter'],
    ;
    '/etc/prometheus':
      ensure => directory,
    ;
    '/etc/prometheus/graphite_mappings.yaml':
      ensure  => file,
      content => @(EOF:yaml),
        ---
        mappings:
          - match: "(vmpooler[\\w-]+)\\.(checkout)\\.([\\w-]+)\\.(.+)"
            match_type: regex
            name: "vmpooler_${2}_${3}"
            labels:
              vmpooler_instance: $1
              pool: $4
          - match: "(vmpooler[\\w-]+)\\.(config)\\.([\\w-]+)\\.(.+)"
            match_type: regex
            name: "vmpooler_${2}_${3}"
            labels:
              vmpooler_instance: $1
              pool: $4
          - match: "(vmpooler[\\w-]+)\\.(connect)\\.([\\w-]+)\\.(.+)"
            match_type: regex
            name: "vmpooler_${2}_${3}"
            labels:
              vmpooler_instance: $1
          - match: "(vmpooler[\\w-]+)\\.(errors)\\.([\\w-]+)\\.(.+)"
            match_type: regex
            name: "vmpooler_${2}_${3}"
            labels:
              vmpooler_instance: $1
              pool: $4
          - match: "(vmpooler[\\w-]+)\\.(migrate_[\\w-]+)\\.(.+)"
            match_type: regex
            name: "vmpooler_${2}"
            labels:
              vmpooler_instance: $1
              compute_node: $3
          - match: "(vmpooler[\\w-]+)\\.([\\w-]+)_(provider_connection_pool)\\.(.+)"
            match_type: regex
            name: "vmpooler_${3}_${4}"
            labels:
              vmpooler_instance: $1
              connection_pool: $2
          - match: "(vmpooler[\\w-]+)\\.(usage)\\.ABS\\.([\\w-]+)\\.(.+)?\\.([\\w-]+)"
            match_type: regex
            name: "vmpooler_${2}"
            labels:
              vmpooler_instance: $1
              user: ABS
              system: $3
              job: $4
              pool: $5
          - match: "(vmpooler[\\w-]+)\\.(usage)\\.([\\w-]+)\\.(.+)"
            match_type: regex
            name: "vmpooler_${2}"
            labels:
              vmpooler_instance: $1
              user: $3
              pool: $4
          - match: "(vmpooler[\\w-]+)\\.([\\w-]+)\\.(.+)"
            match_type: regex
            name: "vmpooler_${2}"
            labels:
              vmpooler_instance: $1
              pool: $3
        | EOF
      notify  => Prometheus::Daemon['graphite_exporter'],
    ;
  }

  class { 'prometheus::graphite_exporter':
    version      => $version,
    user         => 'graphite-exporter',
    group        => 'graphite-exporter',
    manage_user  => false,
    manage_group => false,
    options      => '--graphite.mapping-config=/etc/prometheus/graphite_mappings.yaml',
    require      => Account::User['graphite-exporter'],
  }
}
