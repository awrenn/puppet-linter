##
#
class profile::os::linux::redhat::el {
  include epel

  if $facts['os']['release']['major'] == '7' {
    include profile::os::linux::systemd
  }
}
