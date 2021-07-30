# profile::boot::pxe manages the operations pxe boot server
class profile::boot::pxe (
  String[1] $canonical_fqdn = $facts['networking']['fqdn'],
  String[1] $syslinux_dir = '/usr/share/syslinux/',
  String[1] $tftp_root = '/var/lib/tftpboot',
) {

  profile_metadata::service { $title:
    human_name        => 'PXE Boot Server',
    owner_uid         => 'gene.liverman',
    team              => dio,
    end_users         => ['discuss-sre@puppet.com'],
    escalation_period => 'none',
    downtime_impact   => "Can't do PXE installs of servers",
    other_fqdns       => [],
    notes             => @("NOTES"),
      This provides the ability to do network-based automated installations
      of various operating systems.
      |-NOTES
  }

  if $facts['os']['family'] != 'RedHat' {
    fail("profile::boot::pxe is not yet supported on ${facts['os']['family']}")
  }

  class { 'pxe':
    tftp_root        => $tftp_root,
    syslinux_version => 'system',
  }

  include tftp
  include profile::boot::pxe::custom
  include profile::boot::pxe::tools
  include profile::boot::pxe::os::centos
  include profile::boot::pxe::os::debian
  include profile::boot::pxe::os::esx

  # Webserver setup to host kickstart files.
  include profile::nginx
  include profile::boot::pxe::web
}
