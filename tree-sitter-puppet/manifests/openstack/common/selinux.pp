class profile::openstack::common::selinux {

  class { '::selinux':
    mode => 'permissive',
  }
}
