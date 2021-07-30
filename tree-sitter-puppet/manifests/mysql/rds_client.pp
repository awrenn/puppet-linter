# mysql client configuration for Amazon RDS
# this defined type configures a client to use a remote mysql server
# the main use case is to allow puppet to create mysql databases on the remote
# database server
define profile::mysql::rds_client (
  $rds_host      = undef,
  $root_password = undef,
  $root_user     = root,
  ) {
  # OPS-8466: This causes a duplicate resource error for no apparent reason.
  # include profile::mysql::client

  $config_file = "/etc/mysql/conf.d/${name}.cnf"
  file { $config_file:
    owner => 'root',
    group => 'root',
    mode  => '0640',
  }

  Ini_setting {
    ensure  => present,
    path    => '/etc/mysql/conf.d/rds.cnf',
    section => 'client',
    before  => File[$config_file],
  }

  ini_setting { "rds mysql host for ${name}":
    setting => 'host',
    value   => $rds_host,
  }

  ini_setting { "rds root user for ${name}":
    setting => 'user',
    value   => $root_user,
  }

  ini_setting { "rds root password for ${name}":
    setting => 'password',
    value   => $root_password,
  }
}
