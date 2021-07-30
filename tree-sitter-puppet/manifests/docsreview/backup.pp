class profile::docsreview::backup {
  $application = $::profile::docsreview::application
  $backup_root = "/var/lib/backup/${application}"

  file {
    default:
      ensure => directory,
      owner  => 'root',
      mode   => '0755',
      group  => '0',
    ;
    '/var/lib/backup':
    ;
    $backup_root:
    ;
    "${backup_root}/${application}.sql.gz":
      ensure => file,
      owner  => 'postgres',
      mode   => '0600',
    ;
  }

  cron { "backup_postgres_${application}":
    command => "/usr/bin/pg_dump ${application} --create | nice -n20 gzip --rsyncable >${backup_root}/${application}.sql.gz",
    user    => 'postgres',
    hour    => [0, 6, 12, 18],
    minute  => fqdn_rand(49),
    require => File[$backup_root],
  }
}
