#
# Class used to install carbonate - a collection
# of tools used to help with maintaining a graphite
# cluster
#

class profile::graphite::carbonate {

  package { 'carbonate':
    ensure   => installed,
    provider => pip,
  }

  file { '/opt/graphite/conf/carbonate.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    content => epp('profile/graphite/carbonate.conf.epp'),
    require => Package['carbon'],
  }

}
