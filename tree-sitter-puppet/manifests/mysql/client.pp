# mysql client installation
# this is not needed on mysql servers and will conflict with mariadb-server
class profile::mysql::client {
  include profile::mysql::repo

  class { '::mysql::client':
    package_name => 'mariadb-client',
    require      => Apt::Source['mariadb'],
  }
}
