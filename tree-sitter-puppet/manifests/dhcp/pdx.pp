# Class: profile::dhcp::pdx
# 
# This file only handles DHCP reservations for PDX Engineering networks (10.0.22.0/24, 10.0.150.0/24)
# Other reservations are left here for posterity/reference
# For DHCP reservations on all other PDX networks, please contact IT SysOps
# 
# Please create DHCP reservations outside of the DHCP scope (as defined in Hiera) to avoid IP conflicts
#
class profile::dhcp::pdx {
  profile_metadata::service { $title:
    human_name => 'DHCP server: Portland office',
    team       => itops,
    doc_urls   => [
      'https://confluence.puppetlabs.com/display/IT/DHCP+Service',
    ],
  }

  include profile::dhcp::common

  # OPS-10752 - ignore TSE host for DCHP
  dhcp::host { 'blackhole'     : mac => '00:50:56:A6:DA:D8', ip => '192.168.254.254', ignored => true, }

  # Power8 VMs for Platform team
  # Reserved 10.0.22.20 through 10.0.22.49
  # Reserved 10.0.22.221 through 10.0.22.231 (noted below, too)

  #
  # TSE Mac Minis
  # HELP-3943, HELP-19133
  #
  dhcp::host { 'tsetest1'                           : mac => '10:dd:b1:9e:79:28', ip => '10.0.22.76',  }
  dhcp::host { 'tsetest2'                           : mac => '40:6c:8f:59:47:88', ip => '10.0.22.77',  }
  dhcp::host { 'tsetest3'                           : mac => '68:5b:35:8d:9d:51', ip => '10.0.22.78',  }

  # Test Cisco switches for modules team
  dhcp::host { 'cisco-4507r'                        : mac => '00:0f:23:c0:5f:ff', ip => '10.0.22.83' }
  dhcp::host { 'cisco-4948'                         : mac => '00:1b:53:97:35:ff', ip => '10.0.22.91' }
  dhcp::host { 'cisco-3750'                         : mac => '68:bd:ab:17:99:c0', ip => '10.0.22.162' }
  dhcp::host { 'cisco-3650'                         : mac => 'a0:3d:6f:95:6c:80', ip => '10.0.22.198' }
  dhcp::host { 'cisco-4503'                         : mac => '44:d3:ca:6f:61:4e', ip => '10.0.22.163' }
  dhcp::host { 'cisco-nexus-7000'                   : mac => 'd8:67:d9:0e:6e:23', ip => '10.0.22.164' }
  # Virtual Non-Default VDC created on top of 'cisco-nexus-7000'
  dhcp::host { 'cisco-nexus-7000-non-default'       : mac => '00:00:00:00:00:00', ip => '10.0.22.165' }

  # UCS hosts
  dhcp::host { 'boinc-app-dev-2'                    : mac => '00:25:b5:7d:83:cf', ip => '10.0.22.210' }
  dhcp::host { 'boinc-app-dev-1'                    : mac => '00:40:9d:56:4b:83', ip => '10.0.22.215' }

  #
  # Delivery performance hosts
  # 1U Silicon Mechanics machines in 626c3
  #
  dhcp::host { 'perf-bl02'                          : mac => '00:25:90:6c:56:c8', ip => '10.0.150.20'  }
  dhcp::host { 'perf-bl03'                          : mac => '00:25:90:6a:70:c2', ip => '10.0.150.21'  }
  dhcp::host { 'perf-bl04'                          : mac => '00:25:90:d8:82:5e', ip => '10.0.150.22'  }
  dhcp::host { 'perf-bl06'                          : mac => '00:25:90:d8:81:e6', ip => '10.0.150.24'  }
  dhcp::host { 'perf-bl08'                          : mac => '00:25:90:d8:82:c6', ip => '10.0.150.26'  }
  dhcp::host { 'perf-bl09'                          : mac => '00:25:90:d8:82:36', ip => '10.0.150.27'  }
  dhcp::host { 'perf-bl10'                          : mac => '00:25:90:d8:82:b2', ip => '10.0.150.28'  }
  dhcp::host { 'perf-bl11'                          : mac => '00:25:90:d8:82:b6', ip => '10.0.150.29'  }
  dhcp::host { 'perf-bl12'                          : mac => '00:25:90:d8:82:fe', ip => '10.0.150.30'  }
  dhcp::host { 'perf-bl13'                          : mac => '00:25:90:d8:82:ca', ip => '10.0.150.31'  }

  #
  # Remote power switches for Cisco development hardware
  # https://confluence.puppetlabs.com/display/ECO/Cisco+IOS+Module+Development#CiscoIOSModuleDevelopment-RemotePowerManagement
  #
  dhcp::host { 'pdx-626c7-engnet-pwr1.it.puppet.net': mac => '00:03:ea:05:c8:49', ip => '10.0.22.170' }
  dhcp::host { 'pdx-626c7-engnet-pwr2.it.puppet.net': mac => '00:03:ea:05:d3:5e', ip => '10.0.22.171' }
  dhcp::host { 'pdx-626c7-engnet-pwr3.it.puppet.net': mac => '00:03:ea:05:db:ac', ip => '10.0.22.172' }

}
