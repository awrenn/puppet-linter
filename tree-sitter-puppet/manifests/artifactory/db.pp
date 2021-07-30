##
## Class for Artifactory database machine.
##
class profile::artifactory::db (
  Stdlib::Unixpath $database_dump_directory
  ) {

  $database_dump_script_url = 'puppet:///modules/profile/artifactory/database-dump'
  $database_dump_script_path = '/usr/local/bin/database-dump'

  file { 'database dump directory':
    ensure => 'directory',
    path   => "${database_dump_directory}",
    mode   => '0750',
  }

  file { 'database dump script':
    ensure => 'file',
    owner  => 'postgres',
    path   => $database_dump_script_path,
    source => $database_dump_script_url,
    mode   => '0744',
  }

  cron { 'database_dump':
    command => "${database_dump_script_path} -d ${database_dump_directory} > ${database_dump_directory}/cron.out 2>&1",
    user    => 'postgres',
    hour    => [5, 17],
    minute  => 0,
    require => [
      File['database dump directory'],
      File['database dump script'],
    ],
  }
}
