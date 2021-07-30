class profile::imaging::builder::packer {

  file { '/usr/local/bin/packer':
    ensure => link,
    target => '/opt/packer/packer',
  }

}
