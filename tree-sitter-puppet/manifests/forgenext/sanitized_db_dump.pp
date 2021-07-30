class profile::forgenext::sanitized_db_dump (
  String[1]              $db_host,
  String[1]              $app_db,
  String[1,63]           $scratch_db_user,
  String[1,63]           $scratch_db              = 'sanitized_db_dump',
  String[1]              $cronjob_name            = 'sanitized_db_dump',
  String[1]              $s3_bucket_name          = 'forge-db-sync',
  String[1]              $datalake_s3_bucket_name = 'forge-db-xfer-datalake',
  Boolean                $enabled                 = false,
  Optional[String[1]]    $gcp_svc_acct_key        = undef,
  Optional[String[1]]    $db_password             = undef,
) {

  # make a list of other nodes that are eligible to run the cron job
  $cronjob_nodes = puppetdb_query("inventory {
    facts.classification.group    = '${facts['classification']['group']}' and
    facts.classification.stage    = '${facts['classification']['stage']}' and
    facts.classification.function = '${facts['classification']['function']}' and
    facts.whereami                = '${facts['whereami']}'
  }").map |$value| { $value['facts']['networking']['fqdn'] }

  $cronjob_leader = sort($cronjob_nodes)[0]

  if $enabled {
    if $facts['networking']['fqdn'] == $cronjob_leader {
      # only install the cron job if this is the first node in the list
      $cron_job_ensure = 'present'
      meta_motd::register { 'This server runs the sanitized db dump cron job script': }
    } else {
      $cron_job_ensure = 'absent'
      meta_motd::register { "sanitized db dump cron job runs on node with fqdn: ${cronjob_leader}": }
    }
  } else {
    $cron_job_ensure = 'absent'
  }

  $pgpass_entries = [
    "${db_host}:5432:${app_db}:${scratch_db_user}:${db_password}",
    "${db_host}:5432:${scratch_db}:${scratch_db_user}:${db_password}",
  ]

  $pgpass = join($pgpass_entries, "\n")

  file { '/var/lib/forgeapi/.pgpass':
    ensure  => $cron_job_ensure,
    owner   => 'forgeapi',
    group   => 'forgeapi',
    mode    => '0600',
    content => "${pgpass}\n",
  }

  file { '/var/lib/forgeapi/gcp-db-xfer-svc-acct.json':
    ensure  => ($cron_job_ensure and $gcp_svc_acct_key) ? { true => 'present', default => 'absent' },
    owner   => 'forgeapi',
    group   => 'forgeapi',
    mode    => '0600',
    content => $gcp_svc_acct_key,
  }

  file { '/var/lib/forgeapi/sanitized_db_dump.sh':
    ensure  => $cron_job_ensure,
    owner   => 'forgeapi',
    group   => 'forgeapi',
    mode    => '0700',
    content => template('profile/forgenext/sanitized_db_dump.sh.erb'),
  }

  cron { 'sanitized_db_dump':
    ensure      => $cron_job_ensure,
    command     => '/var/lib/forgeapi/sanitized_db_dump.sh > /dev/null',
    user        => 'forgeapi',
    minute      => '15',
    hour        => '0',
    environment => 'MAILTO=forge@puppet.com',
    require     => File['/var/lib/forgeapi/sanitized_db_dump.sh'],
  }
}
