# mysql metrics collection
class profile::mysql::metrics {
  include profile::metrics

  $metrics_password = hiera('profile::mysql::metrics_password')
  validate_string($metrics_password)

  mysql_user { 'metrics@localhost':
    password_hash => mysql_password($metrics_password),
  }

  mysql_grant { 'metrics@localhost/*.*':
    ensure     => 'present',
    user       => 'metrics@localhost',
    options    => [ 'GRANT' ],
    privileges => [ 'SUPER' ],
    table      => '*.*',
  }

  Diamond::Collector <| title == 'MySQLCollector' |> {
  #diamond::collector { 'MySQLCollector':
    options => {
      'user'   => 'metrics',
      'passwd' => $metrics_password,
      'host'   => 'localhost',
      'port'   => '3306',
      'db'     => 'performance_schema',
    },
    require => Package['python-mysqldb'],
  }

  $package_name = $facts['os']['name'] ? {
    'CentOS' => 'MySQL-python',
    default  => 'python-mysqldb'
  }


  package { 'python-mysqldb':
    ensure  => present,
    name    => $package_name,
    require => Class['mysql::server'],
  }

}
