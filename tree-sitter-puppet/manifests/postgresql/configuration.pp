class profile::postgresql::configuration (
  $replication_master = $::profile::postgresql::params::replication_master,
  $replication_slave  = $::profile::postgresql::params::replication_slave,
  $addslave           = $::profile::postgresql::params::addslave,
  $manage_logging     = $::profile::postgresql::params::manage_logging,
  ){
  include profile::postgresql::params

  $slave_url                  = $::profile::postgresql::params::slave_url
  $master_url                 = $::profile::postgresql::params::master_url
  $log_destination            = $::profile::postgresql::params::log_destination
  $logging_collector          = $::profile::postgresql::params::logging_collector
  $log_min_duration_statement = $::profile::postgresql::params::log_min_duration_statement
  $log_line_prefix            = $::profile::postgresql::params::log_line_prefix
  $max_connections            = $::profile::postgresql::params::max_connections
  $pglogical_replication      = $::profile::postgresql::params::pglogical_replication
  $pgversion                  = $::postgresql::globals::version

  if $pglogical_replication {
    postgresql::server::config_entry { 'wal_level':
      value => 'logical',
    }

    postgresql::server::config_entry { 'max_worker_processes':
      value => '50',
    }

    postgresql::server::config_entry { 'max_replication_slots':
      value => '50',
    }

    postgresql::server::config_entry { 'max_wal_senders':
      value => '50',
    }

    postgresql::server::config_entry { 'shared_preload_libraries':
      value => 'pglogical',
    }
  } else {
    postgresql::server::config_entry { 'wal_level':
      value => 'hot_standby',
    }

    postgresql::server::config_entry { 'max_wal_senders':
      value => '5',
    }
  }

  postgresql::server::config_entry { 'wal_keep_segments':
    value => '32',
  }

  if ( $pgversion =~ /9.[56]/ )
  {
    postgresql::server::config_entry { 'max_wal_size':
      value => '8',
    }
  } else {
    postgresql::server::config_entry { 'checkpoint_segments':
      value => '8',
    }
  }

  if $max_connections {
    postgresql::server::config_entry { 'max_connections':
      value => $max_connections,
    }
  }

  if ( $replication_master == true ) {

    postgresql::server::config_entry { 'archive_mode':
      value => 'on',
    }

    postgresql::server::config_entry { 'archive_command':
      value => "rsync -aq %p postgres@${slave_url}:/var/lib/postgresql/9.3/archive/%f",
    }

    postgresql::server::config_entry { 'archive_timeout':
      value => '3600',
    }
    # Add Postgres Replication Utility Script: pg_check_repstat
    # This checks the replication status on the DB Master
    file { '/sbin/pg_check_repstat':
      ensure  => 'present',
      content => template('profile/postgresql/pg_check_repstat.erb'),
      owner   => '0',
      group   => '0',
      mode    => '0755',
    }
    # Add Postgres Replication Utility Script: pg_check_master_pos
    # This checks the WAL log master position.
    file { '/sbin/pg_check_master_pos':
      ensure  => 'present',
      content => template('profile/postgresql/pg_check_master_pos.erb'),
      owner   => '0',
      group   => '0',
      mode    => '0755',
    }
  }

  if ( $replication_slave == true ) {

    postgresql::server::config_entry { 'hot_standby':
      value => 'on',
    }

    # Add Postgres Replication Utility Script: pg_replicate
    # This auto replicates a slave from a master
    file { '/sbin/pg_replicate':
      ensure  => 'present',
      content => template('profile/postgresql/pg_replicate.erb'),
      owner   => '0',
      group   => '0',
      mode    => '0755',
    }
    # Add Postgres Replication Utility Script: pg_check_slave_pos
    # This checks the WAL log slave position.
    file { '/sbin/pg_check_slave_pos':
      ensure  => 'present',
      content => template('profile/postgresql/pg_check_slave_pos.erb'),
      owner   => '0',
      group   => '0',
      mode    => '0755',
    }
    # Add Postgres Replication Utility Script: pg_promote_slave2master
    # This will promote a Postgres Slave node to a Master DB node.
    file { '/sbin/pg_promote_slave2master':
      ensure  => 'present',
      content => template('profile/postgresql/pg_promote_slave2master.erb'),
      owner   => '0',
      group   => '0',
      mode    => '0755',
    }
  }

  if ( $addslave == true ) {

    postgresql::server::config_entry { 'archive_command':
      value => "rsync -aq %p postgres@${slave_url}:/var/lib/postgresql/9.3/archive/%f",
    }

    postgresql::server::config_entry { 'archive_timeout':
      value => '3600',
    }
  }

  if ( $manage_logging == true ) {

    postgresql::server::config_entry { 'log_destination':
      value => $log_destination,
    }

    postgresql::server::config_entry { 'logging_collector':
      value => $logging_collector,
    }

    postgresql::server::config_entry { 'log_min_duration_statement':
      value => $log_min_duration_statement,
    }

    postgresql::server::config_entry { 'log_line_prefix':
      value => $log_line_prefix,
    }
  }
}
