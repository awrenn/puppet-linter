# Configure all Linux nodes regardless of distro
class profile::os::linux {
  include profile::os::splatnix
  include profile::base::dhclient
  include profile::base::maintenance
  include puppetlabs::scripts
  include ruby

  case $facts['os']['family'] {
    'Debian': { include profile::os::linux::debian }
    'RedHat': { include profile::os::linux::redhat }
    'Suse': { include profile::os::linux::suse }
    default: {
      notify { "Linux family ${facts['os']['family']} is not supported": }
    }
  }

  if $facts['os']['name'] != 'CumulusLinux' {
    include profile::python

    # (OPS-7252) Install hardware utilities on bare metal linux nodes
    if $facts['virtual'] == 'physical' {
      package { ['lshw', 'smartmontools', 'hdparm']:
        ensure => latest,
      }
    }
  }

  # Mitigation for CVE-2016-5696
  sysctl::value { 'net.ipv4.tcp_challenge_ack_limit':
    value => '999999999',
  }

  # Don't show the MOTD via PAM when logging in with SSH. This disables
  # Debian's "dynamic" MOTD.
  file_line { '/etc/pam.d/sshd pam_motd.so':
    path     => '/etc/pam.d/sshd',
    line     => '# session optional pam_motd.so',
    match    => '^[\s#]*session\s+\w+\s+pam_motd\.so',
    multiple => true,
  }

  file {
    default:
      owner => 'root',
      group => 'root',
      mode  => '0644',
    ;
    '/etc/timezone':
      ensure  => file,
      content => 'America/Los_Angeles',
    ;
    '/etc/localtime':
      ensure => symlink,
      target => '/usr/share/zoneinfo/America/Los_Angeles',
      force  => true,
    ;
  }

  if $facts['is_virtual'] == true {
    include profile::os::linux::virtual
  }
}
