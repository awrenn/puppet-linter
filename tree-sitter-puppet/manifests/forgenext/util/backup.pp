class profile::forgenext::util::backup {
  meta_motd::register { 'profile::forgenext::util::backup': }

  file { '/opt/forge_s3_backup':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
  }

  $s3_bucket_name = "forgenext-modules-${facts['classification']['stage']}"
  $backup_dir = '/opt/forge_s3_backup/'

  $hour = [0, 4, 8, 12, 16, 20]
  $minute = '0'

  cron { 'local_s3_copy':
    command => "/usr/bin/aws s3 sync s3://${s3_bucket_name} ${backup_dir}",
    hour    => $hour,
    minute  => $minute,
  }

  # forge developers have asked for a tarball of all forge modules
  # to be made available. This isn't part of our backup strategy.
  # the file will be available at:
  # https://forge-modules-archives.s3-website-us-west-2.amazonaws.com/latest-${facts['classification']['stage']}.tar
  cron { 'forge_modules_archive':
    command => "/bin/tar -c ${backup_dir} | /usr/local/bin/aws s3 cp - s3://forge-modules-archives/latest-${facts['classification']['stage']}.tar",
    hour    => 8,
    minute  => 30,
  }
}
