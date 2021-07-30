# Configure virtual machines running Linux
class profile::os::linux::virtual (
  Integer[0] $swappiness = 25,
) {
  sysctl::value { 'vm.swappiness':
    value => $swappiness,
  }

  # Set the VM's root disk to the noop IO Scheduler so the hypervisor can handle
  # the scheduling.
  case $facts['virtual'] {
    'xen0', 'xen', 'xenu', 'xenhvm':         { $disk_id = 'xvda' }
    'vmware', 'virtualbox', 'lxc', 'docker': { $disk_id = 'sda'  }
    'kvm': {
      if $facts['whereami'] =~ /^linode/ {
        $disk_id = 'sda'
      }
      elsif $facts['whereami'] == 'aws_internal_net_vpc' {
        $disk_id = 'nvme0n1'
      }
      else {
        $disk_id = 'vda'
      }
    }
    default: {
      fail("Disk driver type not identified for io_scheduler in ${title}")
    }
  }
  # http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=2011861
  # https://github.com/zfsonlinux/zfs/issues/6513
  unless versioncmp($facts["kernelmajversion"], '4.17') >= 0 and $facts["os"]["family"] == 'Debian' {
    exec { 'io_scheduler':
      command => "/bin/echo noop > /sys/block/${disk_id}/queue/scheduler",
      unless  => "/bin/grep -E 'noop|none' /sys/block/${disk_id}/queue/scheduler",
    }
  }

  if $facts['virtual'] == 'vmware' {
    # Make sure we get all the proper VMware tools packages installed.
    include vmware
  }
}
