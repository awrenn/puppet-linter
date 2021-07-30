# Class: profile::os::linux::systemd
#
# Manage settings and configuration specific to systemd-based distributions.
#
class profile::os::linux::systemd {
  include systemd

  file { '/var/log/journal':
    ensure => directory,
    mode   => undef,
    owner  => undef,
    group  => undef,
  }

  exec { 'set permissions on journald log directory':
    command     => '/bin/systemd-tmpfiles --create --prefix /var/log/journal',
    refreshonly => true,
    subscribe   => File['/var/log/journal'],
    notify      => Service['systemd-journald'],
  }

  # Systemd has to be prompted to reload unit files when they change.
  #
  # File resources managing unit files should notify both this exec and the
  # corresponding service. (See also PUP-3483.)
  exec { 'puppetlabs-modules systemctl daemon-reload':
    command     => 'systemctl daemon-reload',
    path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
    user        => 'root',
    refreshonly => true,
  }

  Exec['puppetlabs-modules systemctl daemon-reload'] -> Service <| |>
}
