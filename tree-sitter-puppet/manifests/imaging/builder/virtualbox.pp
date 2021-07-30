class profile::imaging::builder::virtualbox {
  include profile::imaging::builder::prerequisites

  yumrepo { 'virtualbox':
    descr    => "Oracle Linux / RHEL / CentOS-${operatingsystemmajrelease} / ${architecture} - VirtualBox",
    baseurl  => "http://download.virtualbox.org/virtualbox/rpm/el/${operatingsystemmajrelease}/${architecture}",
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => 'https://www.virtualbox.org/download/oracle_vbox.asc',
  }

  package { 'VirtualBox-5.1':
    ensure  => 'installed',
    require => Yumrepo['virtualbox'],
  }
}
