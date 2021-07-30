# Automatic Elasticsearch administration
class profile::elasticsearch::admin (
  Integer[1] $logstash_retain_days = 30,
  String[1] $snapshot_repo = 'plops_snapshots_v2',
  String[1] $s3_snapshot_repo = 's3_repository',
) {
  $admin_root = '/opt/es-admin'

  file {
    default:
      owner => 'root',
      group => 'root',
      mode  => '0555',
    ;
    $admin_root:
      ensure  => directory,
      purge   => true,
      force   => true,
      recurse => true,
      source  => 'puppet:///modules/profile/elasticsearch/admin',
    ;
    "${admin_root}/snapshot.sh":
      content => template('profile/elasticsearch/snapshot.sh.erb'),
    ;
  }

  cron { 'Logstash index retention':
    command => "${admin_root}/index_retention.py --host localhost --retain ${logstash_retain_days}",
    user    => 'elasticsearch',
    hour    => 6,
    minute  => 0,
  }

  # This script checks to make sure a recent snapshot exists and removes the previous one if it was successful.
  cron { 'S3 snapshot retention':
    command => "${admin_root}/snapshot_retention.py --es_host 'localhost' --snapshot_repo '${s3_snapshot_repo}'",
    user    => 'elasticsearch',
    hour    => 6,
    minute  => 30,
  }

  # See OPS-8764 for details on why this is needed.
  cron { 'Clear cache':
    command => 'curl -sS localhost:9200/_cache/clear | fgrep -v \'"failed":0\'',
    user    => 'elasticsearch',
    minute  => '*/15',
  }

  # Auto-gen the snapshot name from date
  cron { 'Snapshot indices':
    command => "${admin_root}/snapshot.sh",
    user    => 'elasticsearch',
    hour    => 0,
    minute  => 5,
  }
}
