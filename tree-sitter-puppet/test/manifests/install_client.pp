class profile::postgresql::install_client {

  class { 'postgresql::globals':
    manage_package_repo => true,
  }

  class { 'postgresql::client': }
}
