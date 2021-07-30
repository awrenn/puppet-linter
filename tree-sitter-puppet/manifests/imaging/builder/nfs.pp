class profile::imaging::builder::nfs {
  include nfs::client

  Nfs::Client::Mount <<| server == 'imaging-nfs1-prod.delivery.puppetlabs.net' |>>

  # int-resources is no longer available so set these resources as absent to
  # force a cleanup - these can be removed in due course in the fullness of time
  file { '/srv/int-resources':
    ensure => absent,
    force  => true,
  }
  mount { '/srv/int-resources':
    ensure  => 'absent',
  }
  file { '/opt/int-resources':
    ensure => absent,
  }

  # /var/lib/jenkins is mounted on its own drive
  mount { '/var/lib/jenkins':
    ensure  => 'mounted',
    device  => '/dev/sdc1',
    fstype  => 'ext3',
    options => 'defaults',
    target  => '/etc/fstab',
    require => File['/var/lib/jenkins'],
  }

  #maintain the legacy locations as symlinks
  file { '/opt/puppetlabs-packer':
    ensure => link,
    target => '/srv/packer/puppetlabs-packer',
  }

  file { '/opt/output':
    ensure => link,
    target => '/srv/vagrant',
  }

  file { '/opt/education':
    ensure => link,
    target => '/srv/education',
  }
}
