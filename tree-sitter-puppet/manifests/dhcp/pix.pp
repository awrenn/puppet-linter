# Class: profile::dhcp::pix
#
# Manage dhcp reservations for pittock
#
class profile::dhcp::pix {
  profile_metadata::service { $title:
    human_name => 'DHCP server: Pittock datacenter',
    team       => itops,
    doc_urls   => [
      'https://confluence.puppetlabs.com/display/IT/DHCP+Service',
    ],
  }

  # ----------
  # Reservations
  # ----------

  # LTS ESX
  dhcp::host {
    'pix-jj25-c1-1':
      mac => '00:25:b5:42:ae:2f',
      ip  => '10.16.22.10'
      ;
    'pix-jj25-c1-2':
      mac => '00:25:b5:42:ad:ef',
      ip  => '10.16.22.11'
      ;
    'pix-jj25-c1-3':
      mac => '00:25:b5:42:ad:6f',
      ip  => '10.16.22.12'
      ;
    'pix-jj25-c1-4':
      mac => '00:25:b5:42:ae:0e',
      ip  => '10.16.22.13'
      ;
    'pix-jj25-c1-5':
      mac => '00:25:b5:42:ad:ce',
      ip  => '10.16.22.14'
      ;
    'pix-jj25-c1-6':
      mac => '00:25:b5:42:ad:4e',
      ip  => '10.16.22.15'
      ;
    'pix-jj25-c1-7':
      mac => '00:25:b5:42:ad:fd',
      ip  => '10.16.22.16'
      ;
    'pix-jj25-c1-8':
      mac => '00:25:b5:42:ad:8d',
      ip  => '10.16.22.17'
      ;
  }

  # ITOps KVM host
  dhcp::host {
    'pix-hyperv-1-prod':
      mac => '18:66:da:93:54:50',
      ip  => '10.16.22.76'
      ;
  }

  # ITOps VPN hosts
  dhcp::host {
    'vpn-corp-prod-1':
      mac => '52:54:00:e3:df:f9',
      ip  => '10.16.23.27'
      ;
  }

  # ITOps LDAP
  dhcp::host {
    'ldap-prod-1':
      mac => '52:54:00:c7:82:1c',
      ip  => '10.16.22.88'
      ;
  }
  dhcp::host {
    'ldap-prod-2':
      mac => '52:54:00:48:1e:ff',
      ip  => '10.16.22.89'
      ;
  }

  # cinext mesos agents
  dhcp::host {
    'cinext-mesosagent-prod-133':
      mac => '00:25:b5:42:ae:39',
      ip  => '10.16.76.2'
      ;
    'cinext-mesosagent-prod-134':
      mac => '00:25:b5:42:ae:29',
      ip  => '10.16.76.3'
      ;
    'cinext-mesosagent-prod-135':
      mac => '00:25:b5:42:ae:19',
      ip  => '10.16.76.4'
      ;
    'cinext-mesosagent-prod-136':
      mac => '00:25:b5:42:ae:09',
      ip  => '10.16.76.5'
      ;
    'cinext-mesosagent-prod-137':
      mac => '00:25:b5:42:ad:f9',
      ip  => '10.16.76.6'
      ;
    'cinext-mesosagent-prod-138':
      mac => '00:25:b5:42:ad:e9',
      ip  => '10.16.76.7'
      ;
    'cinext-mesosagent-prod-139':
      mac => '00:25:b5:42:ad:d9',
      ip  => '10.16.76.8'
      ;
    'cinext-mesosagent-prod-140':
      mac => '00:25:b5:42:ad:c9',
      ip  => '10.16.76.9'
      ;
  }

  # CI Mac Pro's
  dhcp::host { 'pix-jj27-macpro-1':  mac => '00:3e:e1:ce:fc:9a', ip  => '10.16.22.162', } # :9b
  dhcp::host { 'pix-jj28-macpro-2':  mac => '00:3e:e1:ce:fc:7c', ip  => '10.16.23.74', } # :7d
  dhcp::host { 'pix-jj28-macpro-3':  mac => '00:3e:e1:ce:fb:e3', ip  => '10.16.23.108', } # :e4
  dhcp::host { 'pix-jj29-macpro-4':  mac => '00:3e:e1:ce:fb:bb', ip  => '10.16.22.171', } # :bc
  dhcp::host { 'pix-jj29-macpro-5':  mac => '00:3e:e1:cf:06:96', ip  => '10.16.23.142', } # :97

  # CI Dell R640's
  dhcp::host { 'pix-jj26-u22':       mac => 'b0:26:28:b3:71:06', ip  => '10.16.23.15', }
  dhcp::host { 'pix-jj27-u22':       mac => 'b0:26:28:b3:32:4e', ip  => '10.16.23.16', }
  dhcp::host { 'pix-jj27-u21':       mac => 'b0:26:28:b3:26:c6', ip  => '10.16.23.17', }
  dhcp::host { 'pix-jj27-u20':       mac => 'b0:26:28:b3:4e:80', ip  => '10.16.23.18', }
  dhcp::host { 'pix-jj27-u19':       mac => 'b0:26:28:b3:2d:3e', ip  => '10.16.23.19', }
  dhcp::host { 'pix-jj29-u22':       mac => 'b0:26:28:b3:41:ea', ip  => '10.16.23.24', }
  dhcp::host { 'pix-jj29-u21':       mac => 'b0:26:28:b3:65:24', ip  => '10.16.23.25', }
  dhcp::host { 'pix-jj29-u20':       mac => 'b0:26:28:b3:5b:82', ip  => '10.16.23.26', }
  dhcp::host { 'pix-jj29-u19':       mac => 'b0:26:28:b3:23:42', ip  => '10.16.23.27', }

  # osx-signer
  dhcp::host { 'osx-signer-1':       mac => '00:50:56:98:22:df', ip  => '10.16.76.39', }

}
