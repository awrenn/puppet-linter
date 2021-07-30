class profile::postgresql::install(
  $metrics = true,
){
  include profile::server::params

  class { '::postgresql::globals':
    manage_package_repo => true,
  }

  class { 'postgresql::server':
    ip_mask_deny_postgres_user => '0.0.0.0/32',
    listen_addresses           => '*',
  }

  class { 'postgresql::server::contrib': }

  ::postgresql::server::role { 'ops_user':
    password_hash =>  postgresql_password('ops_user', 'Aeshaim9eeheeQuu'),
  }
  ::postgresql::server::pg_hba_rule { 'ops_user_access':
    type        => 'host',
    address     => '127.0.0.1/32',
    user        => 'ops_user',
    database    => 'all',
    auth_method => 'password',
  }

}
