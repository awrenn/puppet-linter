# mysql database configuration
class profile::mysql::database (
  $db_name,
  $db_user,
  $db_pass,
  $db_source,
){

  mysql::db { $db_name:
    charset  => 'latin1',
    collate  => 'latin1_swedish_ci',
    grant    => ['ALL PRIVILEGES'],
    host     => $db_source,
    password => $db_pass,
    user     => $db_user,
  }
}
