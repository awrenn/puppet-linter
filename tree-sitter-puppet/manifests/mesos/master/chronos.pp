# Class: profile::mesos::master::chronos
#
class profile::mesos::master::chronos {
  $chronos_ver = hiera('profile::mesos::master::chronos::version', 'installed')

  meta_motd::register { 'Chronos (profile::mesos::master::chronos)': }

  file { '/etc/chronos/conf/mail_server': content => 'localhost:25' }
  file { '/etc/chronos/conf/mail_from':   content => "chronos@${facts['networking']['domain']}" }

  package { 'chronos':
    ensure  => $chronos_ver,
    require => Class['profile::mesos::master'],
  }

  service { 'chronos':
    ensure  => running,
    enable  => true,
    require => Package['chronos'],
  }
}
