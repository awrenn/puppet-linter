# Class: profile::dhcp::pdx_test
#
# Manage the dhcp for test network in pdx
#
class profile::dhcp::pdx_test {
  profile_metadata::service { $title:
    human_name => 'DHCP server: Testnet',
    team       => itops,
    doc_urls   => [
      'https://confluence.puppetlabs.com/display/IT/DHCP+Service',
      'https://confluence.puppetlabs.com/display/SRE/Testnet',
    ],
  }

  include profile::dhcp::common

  # ----------
  # Reservations
  # ----------

  dhcp::host { 'pdx-626c6-chassis1-2-test': mac => '00:25:b5:00:01:df', ip => '10.28.22.15', }
  dhcp::host { 'pdx-626c6-chassis1-1-test': mac => '00:25:b5:00:01:9f', ip => '10.28.22.16', }
  dhcp::host { 'pdx-626c6-chassis1-3-test': mac => '00:25:b5:00:01:0f', ip => '10.28.22.19', }

  dhcp::host { 'slice-controller1-test':    mac => '00:50:56:90:cb:55', ip => '10.28.22.130', }
  dhcp::host { 'slice-controller2-test':    mac => '00:50:56:90:6b:8c', ip => '10.28.22.131', }
  dhcp::host { 'slice-controller3-test':    mac => '00:50:56:90:d0:ed', ip => '10.28.22.132', }
  dhcp::host { 'slice-gw1-test':            mac => '00:50:56:90:06:59', ip => '10.28.22.140', }
  dhcp::host { 'slice-gw2-test':            mac => '00:50:56:90:3b:e6', ip => '10.28.22.141', }
  dhcp::host { 'slice-gw3-test':            mac => '00:50:56:90:03:c5', ip => '10.28.22.142', }
  dhcp::host { 'slice-compute1-test':       mac => '00:25:b5:00:00:ef', ip => '10.28.22.190', }
  dhcp::host { 'slice-compute2-test':       mac => '00:25:b5:00:02:8f', ip => '10.28.22.191', }
  dhcp::host { 'slice-compute3-test':       mac => '00:25:b5:00:02:4f', ip => '10.28.22.192', }

}
