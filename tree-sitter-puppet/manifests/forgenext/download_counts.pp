class profile::forgenext::download_counts () {
  $cronjob_name = 'download_counts_cron'
  # make a list of other nodes that are eligible to run the cron job
  $cronjob_nodes = puppetdb_query("inventory {
    facts.classification.function = '${facts['classification']['function']}' and
    facts.classification.group = '${facts['classification']['group']}' and
    facts.classification.stage = '${facts['classification']['stage']}' and
    facts.whereami = '${facts['whereami']}'
  }").map |$value| { $value['facts']['networking']['fqdn'] }
  $cronjob_leader = $cronjob_nodes.sort()[0]
  if $facts['networking']['fqdn'] == $cronjob_leader {
    # only install the cron job if this is the first node in the list
    $cron_job_ensure = 'present'
    meta_motd::register { 'This server runs the download count cron job script': }
  } else {
    $cron_job_ensure = 'absent'
    meta_motd::register { "download count cron job runs on node with fqdn: ${cronjob_leader}": }
  }

  file { '/var/lib/forgeapi/download_counts.sh':
    ensure => 'present',
    owner  => 'forgeapi',
    group  => 'forgeapi',
    mode   => '0700',
    source => 'puppet:///modules/profile/forgenext/download_counts.sh',
  }

  cron { 'download_counts':
    ensure  => $cron_job_ensure,
    command => '/var/lib/forgeapi/download_counts.sh',
    user    => 'forgeapi',
    minute  => [0,15,30,45],
    hour    => '*',
    require => File['/var/lib/forgeapi/download_counts.sh'],
  }
}
