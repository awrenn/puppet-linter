# mysql database configuration
class profile::mysql::server (
  $root_password,
  $buffer_pool_size = '256M',
  $tmp_table_size   = '128M',
  $query_cache_type = '0',
  $query_cache_size = '0M', #query cache is usually harmful
  $key_buffer_size  = '128M',
  $restart          = true,
  $brand            = 'mariadb',
){

  validate_string($root_password)
  validate_string($buffer_pool_size)
  validate_string($tmp_table_size)
  validate_string($query_cache_type)
  validate_string($query_cache_size)
  validate_string($key_buffer_size)

  include profile::mysql::repo
  include profile::server::params

  if ($profile::server::metrics == true) {
    include profile::mysql::metrics
  }

  if ($root_password == 'lifhali2309cdDa') {
    notify {'using default mysql root password in profile::mysql::server': }
  }

  user { 'mysql':
    ensure   => 'present',
    comment  => 'MySQL Server',
    home     => '/var/lib/mysql',
    password => '!',
    shell    => '/bin/false',
    system   => true,
  }

  $package_name = $brand ? {
    'mysql'          => 'mysql-community-server',
    'mariadb'        => 'mariadb-server',
    default          => '',
  }

  $service_name = $facts['os']['name'] ? {
    'CentOS' => 'mysqld',
    default  => 'mysql'
  }


  package { 'cyrus-sasl-devel':
    ensure => present,
  }

  class { 'mysql::server':
    require          => User['mysql'],
    root_password    => $root_password,
    service_name     => $service_name,
    package_name     => $package_name,
    restart          => $restart,
    override_options => { 'mysqld' =>
      {
      'max_connections'                => '1024',
      'innodb_buffer_pool_size'        => $buffer_pool_size,
      'bind_address'                   => '0.0.0.0',
      'tmp_table_size'                 => $tmp_table_size,
      'max_heap_table_size'            => $tmp_table_size,
      'key_buffer_size'                => $key_buffer_size,
      'table_cache'                    => '2000',
      'thread_cache'                   => '50',
      'open-files-limit'               => '65535',
      'table_definition_cache'         => '4096',
      'table_open_cache'               => '2048',
      'query_cache_type'               => $query_cache_type,
      'query_cache_size'               => $query_cache_size,
      'innodb_flush_method'            => 'O_DIRECT',
      'innodb_flush_log_at_trx_commit' => '1',
      'innodb_file_per_table'          => '1',
      'long_query_time'                => '5',
      'max-allowed-packet'             => '16M',
      'max-connect-errors'             => '1000000',
      'sort-buffer-size'               => '1M',
      'read-buffer-size'               => '1M',
      'read-rnd-buffer-size'           => '8M',
      'join-buffer-size'               => '1M',
      'default-storage-engine'         => 'InnoDB',
      'innodb'                         => 'FORCE',
      'innodb-log-buffer-size'         => '64M',
      'innodb-log-file-size'           => '128M',
      'innodb-log-files-in-group'      => '2',
      'slow-query-log'                 => '1',
      'slow-query-log-file'            => '/var/lib/mysql/slow-log',
      'long-query-time'                => '5',
      'performance_schema'             => true,
      },
    },
  }

  # This is the equivalent of running mysql_secure_installation
  # remove default credentials and demo data
  class { 'mysql::server::account_security':
    require => Class['mysql::server'],
  }

}
