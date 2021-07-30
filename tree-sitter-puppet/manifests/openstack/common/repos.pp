##
#
class profile::openstack::common::repos {

  # Zookeeper Repository Managed in profile::openstack::zookeeper

  $erlang_exclude = $facts['classification']['function'] ? {
    'gw'    => { 'exclude' => 'erlang*', },
    default => {}
  }

  class { '::openstack_extras::repo::redhat::redhat':
    manage_rdo    => false,
    manage_epel   => false,
    repo_defaults => $erlang_exclude,
  }

  file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization':
    source => 'puppet:///modules/profile/openstack/repos/RPM-GPG-KEY-CentOS-SIG-Virtualization',
  }

  #Manage/disable repos via puppet
  yumrepo { 'rdo-release':
    baseurl  => 'http://mirror.centos.org/centos/$releasever/cloud/$basearch/openstack-mitaka/',
    descr    => 'rdo-release-$releasever',
    enabled  => '0',
    gpgcheck => '0',
  }

  yumrepo { 'centos-openstack-mitaka':
    baseurl  => 'http://mirror.centos.org/centos/$releasever/cloud/$basearch/openstack-mitaka/',
    descr    => 'centos-openstack-mitaka-$releasever',
    enabled  => '0',
    gpgcheck => '0',
  }

  # QEMU/KVM that supports live snapshots
  yumrepo { 'centos-qemu-ev':
    baseurl  => 'http://mirror.centos.org/centos/$releasever/virt/$basearch/kvm-common/',
    descr    => 'CentOS-$releasever - QEMU EV',
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization',
    require  => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization'],
  }
  yumrepo { 'centos-qemu-ev-test':
    baseurl  => 'http://buildlogs.centos.org/centos/$releasever/virt/$basearch/kvm-common/',
    descr    => 'CentOS-$releasever - QEMU EV Testing',
    enabled  => '0',
    gpgcheck => '1',
    gpgkey   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization',
    require  => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization'],
  }
  yumrepo { 'mariadb':
    descr    => 'mariadb',
    enabled  => 1,
    baseurl  => 'http://yum.mariadb.org/10.0/centos7-amd64',
    gpgcheck => 1,
    gpgkey   => 'https://yum.mariadb.org/RPM-GPG-KEY-MariaDB',
  }

  $midonet_repo = $facts['classification']['stage'] ? {
    'test'  => 'stable',
    default => 'stable'
  }

  yumrepo { 'midonet':
    descr    => 'MidoNet',
    enabled  => 1,
    baseurl  => "http://builds.midonet.org/midonet-5.2/${midonet_repo}/el7/",
    gpgcheck => 1,
    gpgkey   => 'http://builds.midonet.org/midorepo.key',
  }

  yumrepo { 'midonet-openstack-integration':
    descr    => 'MidoNet OpenStack Integration',
    enabled  => 1,
    baseurl  => "http://builds.midonet.org/openstack-mitaka/${midonet_repo}/el7/",
    gpgcheck => 1,
    gpgkey   => 'http://builds.midonet.org/midorepo.key',
  }

  yumrepo { 'midonet-third-party':
    descr    => 'MidoNet 3rd Party Tools and Libraries',
    enabled  => 1,
    baseurl  => 'http://builds.midonet.org/misc/stable/el7/',
    gpgcheck => 1,
    gpgkey   => 'http://builds.midonet.org/midorepo.key',
  }

  yumrepo { 'datastax':
    descr    => 'datastax',
    enabled  => 1,
    baseurl  => 'http://rpm.datastax.com/community',
    gpgcheck => 0,
    gpgkey   => 'https://rpm.datastax.com/rpm/repo_key',
  }

  $sysops_repo = $facts['classification']['stage'] ? {
    'test'  => 'repos-test',
    default => 'repos'
  }

  # Packages built to make OpenStack Kilo work, there is other stuff useful to
  # the infra here too but is no longer a requirement for a functional OpenStack
  # install as of Mitaka.
  yumrepo { 'sysops-openstack':
    baseurl  => "https://${sysops_repo}.ops.puppetlabs.net/sysops-openstack/7/x86_64",
    descr    => 'Puppet Labs OpenStack Re-Repository',
    enabled  => 1,
    gpgcheck => 0,
  }
}
