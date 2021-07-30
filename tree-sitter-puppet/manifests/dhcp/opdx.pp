# Class: profile::dhcp::opdx
#
# Manage the dhcp for opus colo network
# Please create DHCP reservations outside of the DHCP scope (as defined in Hiera) to avoid IP conflicts
#
class profile::dhcp::opdx {
  profile_metadata::service { $title:
    human_name => 'DHCP server: Opus datacenter',
    team       => itops,
    doc_urls   => [
      'https://confluence.puppetlabs.com/display/IT/DHCP+Service',
    ],
  }

  include profile::dhcp::common
  # Pittock does not have its own DHCP servers
  include profile::dhcp::pix

  # ----------
  # Reservations
  # ----------

  # Windows virtualization host null mac makes it non-reservable, for static use
  dhcp::host { 'windows-hyperv-dev-1': mac => '00:00:00:00:00:00', ip => '10.32.22.11'}

  # Monitoring servers
  dhcp::host { 'mon-icinga1-prod': mac => '0c:c4:7a:04:b0:3a', ip => '10.32.22.15' }
  dhcp::host { 'netapp-nabox':     mac => '00:50:56:87:b3:31', ip => '10.32.22.17' }
  dhcp::host { 'mon-icinga2-prod': mac => '00:50:56:98:aa:6a', ip => '10.32.22.19' }
  # Netflow
  dhcp::host { 'opdx-flow01-prod': mac => '00:25:90:33:6a:81', ip => '10.32.22.20', }

  dhcp::host { 'power8-rhel83-8':  mac => '52:54:00:12:11:36', ip => '10.32.22.26' }

  dhcp::host { 'power8-rhel83-9':  mac => '52:54:00:9d:b7:24', ip => '10.32.22.28' }

  dhcp::host { 'power8-rhel83-10': mac => '52:54:00:77:28:08', ip => '10.32.22.30' }
  dhcp::host { 'power8-rhel83-11': mac => '52:54:00:a1:78:ee', ip => '10.32.22.31' }

  # Nexpose scan engines and Puppet Remediate
  dhcp::host { 'nexpose-scanengine-prod-1': mac => '00:50:56:87:80:9e', ip => '10.32.22.33' }
  dhcp::host { 'remediate-app-prod-1':      mac => '00:50:56:87:e4:38', ip => '10.32.22.213' }
  dhcp::host { 'remediate-app-test-1':      mac => '00:50:56:87:d0:1f', ip => '10.32.22.36' }

  dhcp::host { 'graphite-be1-prod':  mac => '48:8b:2c:25:3e:2f', ip => '10.32.22.35', }
  dhcp::host { 'graphite-be2-prod':  mac => '48:8b:2c:25:3f:19', ip => '10.32.22.37', }
  dhcp::host { 'opdx-a2-chassis1-4': mac => '48:8b:2c:25:3e:bd', ip => '10.32.22.39', }

  # SLICE
  # This address is not handed out by DHCP. Wanted to make reservation more visible.
  dhcp::host { 'slice-pdx1-prod': mac => '00:00:00:00:00:00', ip => '10.32.22.42', }

  dhcp::host { 'power8-rhel83-12': mac => '52:54:00:f5:4f:19', ip => '10.32.22.46' }

  dhcp::host { 'pdx-lightingserver-prod': mac => '00:50:56:98:41:27', ip => '10.32.22.51', }

  dhcp::host { 'opdx-a2-power4':     mac => '98:be:94:73:69:ff', ip => '10.32.22.56', }

  # Production VMware reservations
  dhcp::host { 'opdx-a2-chassis1-1': mac => '48:8b:2c:25:3f:cd', ip => '10.32.22.60', }
  dhcp::host { 'opdx-a2-chassis1-2': mac => '48:8b:2c:25:3f:4d', ip => '10.32.22.61', }
  dhcp::host { 'opdx-a2-chassis1-3': mac => '48:8b:2c:25:3e:8d', ip => '10.32.22.62', }

  # ESO profiling VMware reservations
  dhcp::host { 'opdx-a2-chassis1-5': mac => '48:8b:2c:25:3f:cc', ip => '10.32.22.64', }
  dhcp::host { 'opdx-a2-chassis1-6': mac => '48:8b:2c:25:3f:4c', ip => '10.32.22.65', }

  # Puppet VMware reservations
  dhcp::host { 'opdx-a0-chassis2-1': mac => '48:8b:2c:25:3f:76', ip => '10.32.22.67', }
  dhcp::host { 'opdx-a0-chassis2-2': mac => '48:8b:2c:25:3f:35', ip => '10.32.22.70', }

  dhcp::host { 'power8-alpine-4':     mac => '52:54:00:03:0d:52', ip => '10.32.22.75' }
  dhcp::host { 'power8-sles12-14':    mac => '52:54:00:4a:5b:09', ip => '10.32.22.78' }
  dhcp::host { 'power8-rhel73-4':     mac => '52:54:00:53:cb:4e', ip => '10.32.22.79' }
  dhcp::host { 'arm64-centos7-9':     mac => '52:54:00:30:41:24', ip => '10.32.22.84', }
  dhcp::host { 'arm64-centos7-13':    mac => '52:54:00:08:1b:6b', ip => '10.32.22.87', }
  dhcp::host { 'supportupload1-prod': mac => '00:50:56:98:e5:83', ip => '10.32.22.95', }

  dhcp::host { 'power8-sles12-6':     mac => '52:54:00:73:85:09', ip => '10.32.22.103' }
  dhcp::host { 'power8-sles12-3':     mac => '52:54:00:3e:eb:3e', ip => '10.32.22.112' }
  dhcp::host { 'power8-ubuntu1604-9': mac => '52:54:00:3e:44:f8', ip => '10.32.22.121' }
  dhcp::host { 'power8-rhel73-3':     mac => '52:54:00:21:9f:ec', ip => '10.32.22.123' }
  dhcp::host { 'arm64-centos7-10':    mac => '52:54:00:6b:25:0a', ip => '10.32.22.125' }
  dhcp::host { 'power8-sles12-4':     mac => '52:54:00:51:0e:16', ip => '10.32.22.126' }
  dhcp::host { 'arm64-centos7-8':     mac => '52:54:00:b7:fd:5e', ip => '10.32.22.128' }
  dhcp::host { 'power8-sles12-11':    mac => '52:54:00:7c:fe:82', ip => '10.32.22.131' }
  dhcp::host { 'arm64-centos7-7':     mac => '52:54:00:f0:26:f0', ip => '10.32.22.147' }
  dhcp::host { 'arm64-centos7-12':    mac => '52:54:00:16:aa:a5', ip => '10.32.22.149' }
  dhcp::host { 'power8-rhel73-6':     mac => '52:54:00:06:6e:42', ip => '10.32.22.151' }

  dhcp::host { 'opdx-a0-chassis2-6':  mac => '48:8b:2c:25:3f:79', ip => '10.32.22.184', }

  dhcp::host { 'power8-rhel73-12':    mac => '52:54:00:4d:f7:3f', ip => '10.32.22.185' }
  dhcp::host { 'arm64-centos7-14':    mac => '52:54:00:64:89:f6', ip => '10.32.22.212' }

  # Puppet Infra
  # 10.32.22.221 - 10.32.22.241
  dhcp::host { 'ghost-dataingest-prod-1': mac   => '00:50:56:87:f8:e4', ip => '10.32.22.221', }

  dhcp::host { 'logstash-index01-prod':   mac   => '00:50:56:9b:f8:d6', ip => '10.32.22.228', }
  dhcp::host { 'logstash-index02-prod':   mac   => '00:50:56:9b:3d:51', ip => '10.32.22.229', }
  dhcp::host { 'logstash-lb1':            mac   => '00:50:56:9b:0e:ed', ip => '10.32.22.230', }
  dhcp::host { 'logstash-lb02-prod':      mac   => '00:50:56:9b:ed:5b', ip => '10.32.22.231', }
  dhcp::host { 'pe-compiler-prod-5':      mac   => '00:50:56:87:c1:8c', ip => '10.32.22.232', }
  dhcp::host { 'pe-compiler-prod-7':      mac   => '00:50:56:87:f8:05', ip => '10.32.22.234', }
  dhcp::host { 'graphite-lb03-prod':      mac   => '00:50:56:98:33:3a', ip => '10.32.22.235', }
  dhcp::host { 'graphite-lb04-prod':      mac   => '00:50:56:98:6b:92', ip => '10.32.22.236', }
  dhcp::host { 'graphite-relay01-prod':   mac   => '00:50:56:9b:ce:a0', ip => '10.32.22.237', }
  dhcp::host { 'graphite-relay02-prod':   mac   => '00:50:56:9b:b8:52', ip => '10.32.22.238', }

  dhcp::host { 'reposado':                mac => '00:50:56:98:77:49', ip => '10.32.22.242', }
  dhcp::host { 'munki-test1':             mac => '00:50:56:98:7b:88', ip => '10.32.22.243', }
  dhcp::host { 'itpe-mom1-prod':          mac => '00:50:56:98:fb:a8', ip => '10.32.22.247', }

  dhcp::host { 'power8-rhel73-1':         mac => '52:54:00:2d:77:ed', ip => '10.32.23.29' }
  dhcp::host { 'power8-ubuntu1604-10':    mac => '52:54:00:4d:5f:4a', ip => '10.32.23.36' }
  dhcp::host { 'power8-sles12-5':         mac => '52:54:00:6d:42:2b', ip => '10.32.23.41' }

  # RADIUS Servers
  dhcp::host { 'radius-opdx-prod-2':    mac => '00:50:56:98:ca:a4', ip => '10.32.23.49', }

  dhcp::host { 'power8-sles12-8':       mac => '52:54:00:3f:65:15', ip => '10.32.23.57' }
  dhcp::host { 'arm64-centos7-11':      mac => '52:54:00:47:cc:59', ip => '10.32.23.84' }
  dhcp::host { 'power8-rhel73-2':       mac => '52:54:00:64:db:d4', ip => '10.32.23.94' }
  dhcp::host { 'arm64-centos7-3':       mac => '52:54:00:84:e3:e8', ip => '10.32.23.98' }
  dhcp::host { 'opdx-a1-power1':        mac => '98:be:94:73:91:af', ip => '10.32.23.102' }
  dhcp::host { 'power8-sles12-12':      mac => '52:54:00:18:43:cc', ip => '10.32.23.113' }
  dhcp::host { 'power8-alpine-5':       mac => '52:54:00:5c:3e:32', ip => '10.32.23.150' }
  dhcp::host { 'power8-alpine-6':       mac => '52:54:00:1F:EC:F6', ip => '10.32.23.151' }
  dhcp::host { 'arm64-centos7-1':       mac => '52:54:00:2c:0f:24', ip => '10.32.23.152' }
  dhcp::host { 'power8-sles12-7':       mac => '52:54:00:4c:e4:60', ip => '10.32.23.153' }
  dhcp::host { 'power8-ubuntu1604-11':  mac => '52:54:00:3c:98:02', ip => '10.32.23.154' }
  dhcp::host { 'arm64-centos7-4':       mac => '52:54:00:1d:c4:2e', ip => '10.32.23.164' }
  dhcp::host { 'power8-sles12-1':       mac => '52:54:00:28:ae:f3', ip => '10.32.23.172' }
  dhcp::host { 'arm64-centos7-2':       mac => '52:54:00:ce:7f:37', ip => '10.32.22.175' }
  dhcp::host { 'power8-sles12-2':       mac => '52:54:00:0e:41:be', ip => '10.32.23.187' }

  # Infracore Consul
  dhcp::host { 'consul-app-prod-1':     mac   => '00:50:56:ad:b9:ff', ip  => '10.32.23.189', }
  dhcp::host { 'consul-app-prod-2':     mac   => '00:50:56:ad:53:4c', ip  => '10.32.23.190', }
  dhcp::host { 'consul-app-prod-3':     mac   => '00:50:56:ad:cb:d9', ip  => '10.32.23.191', }

  dhcp::host { 'power8-rhel73-11':      mac => '52:54:00:61:e5:54', ip => '10.32.23.196' }
  dhcp::host { 'arm64-centos7-5':       mac => '52:54:00:72:a4:3b', ip => '10.32.23.199' }
  dhcp::host { 'power8-rhel73-5':       mac => '52:54:00:35:85:57', ip => '10.32.23.202' }
  dhcp::host { 'power8-sles12-13':      mac => '52:54:00:28:23:ae', ip => '10.32.23.204' }
  dhcp::host { 'power8-rhel73-7':       mac => '52:54:00:4c:33:06', ip => '10.32.23.209' }

  # Infracore Consul dev
  dhcp::host { 'consul-app-dev-1':      mac   => '00:50:56:ad:b0:72', ip  => '10.32.23.211', }
  dhcp::host { 'consul-app-dev-2':      mac   => '00:50:56:ad:38:0f', ip  => '10.32.23.212', }
  dhcp::host { 'consul-app-dev-3':      mac   => '00:50:56:ad:63:18', ip  => '10.32.23.213', }

  dhcp::host { 'power8-rhel73-8':         mac => '52:54:00:26:e6:db', ip => '10.32.23.222' }

  dhcp::host { 'arm64-centos7-6':         mac => '52:54:00:50:fa:c9', ip => '10.32.23.229' }

  dhcp::host { 'power8-rhel83-1':         mac => '52:54:00:e9:36:0c', ip => '10.32.23.230' }
  dhcp::host { 'power8-rhel83-2':         mac => '52:54:00:c9:4e:c9', ip => '10.32.23.231' }
  dhcp::host { 'power8-rhel83-3':         mac => '52:54:00:8a:eb:70', ip => '10.32.23.232' }
  # Icinga2 master reservation
  dhcp::host { 'icinga-master01-prod':    mac => '00:50:56:98:e8:3d', ip => '10.32.23.233', }
  dhcp::host { 'power8-rhel83-4':         mac => '52:54:00:83:dd:ac', ip => '10.32.23.234' }
  dhcp::host { 'repo-proxy-prod-1':       mac => '00:50:56:87:1c:47', ip => '10.32.23.235', }
  dhcp::host { 'webhook-proxy-prod-2':    mac => '00:50:56:87:4f:c3', ip => '10.32.23.236', }
  dhcp::host { 'power8-rhel83-5':         mac => '52:54:00:e4:4e:26', ip => '10.32.23.237' }
  dhcp::host { 'power8-alpine-1':         mac => '52:54:00:1e:8e:29', ip => '10.32.23.238' }
  dhcp::host { 'power8-alpine-2':         mac => '52:54:00:3e:09:e6', ip => '10.32.23.239' }
  dhcp::host { 'power8-alpine-3':         mac => '52:54:00:11:df:75', ip => '10.32.23.240' }

  # Platform9 OpenStack compute nodes
  dhcp::host {
    'p9openstack-compute-opdx-prod-1':
      mac => '48:8B:2C:25:3F:D3',
      ip  => '10.32.23.241',
    ;
    'p9openstack-compute-opdx-prod-2':
      mac => '48:8B:2C:25:3E:B4',
      ip  => '10.32.23.242',
    ;
    'p9openstack-compute-opdx-prod-3':
      mac => '48:8B:2C:25:3F:A3',
      ip  => '10.32.23.243',
    ;
    'p9openstack-compute-opdx-prod-4':
      mac => '48:8B:2C:25:3F:73',
      ip  => '10.32.23.244',
    ;
    'p9openstack-compute-opdx-prod-5':
      mac => '48:8B:2C:25:3F:43',
      ip  => '10.32.23.245',
    ;
    'p9openstack-compute-opdx-prod-6':
      mac => '48:8B:2C:25:3F:13',
      ip  => '10.32.23.246',
    ;
    'p9openstack-compute-opdx-prod-7':
      mac => '48:8B:2C:25:3E:83',
      ip  => '10.32.23.247',
    ;
    'p9openstack-compute-opdx-prod-8':
      mac => '48:8B:2C:25:3E:E4',
      ip  => '10.32.23.248',
    ;
    'p9openstack-compute-opdx-prod-9':
      mac => 'b0:26:28:b3:2c:ac',
      ip  => '10.32.23.251',
    ;
    'p9openstack-compute-opdx-prod-10':
      mac => 'b0:26:28:b3:40:b6',
      ip  => '10.32.23.252',
    ;
  }

  dhcp::host { 'power8-rhel83-6':         mac => '52:54:00:5c:58:62', ip => '10.32.23.253' }
  dhcp::host { 'power8-rhel83-7':         mac => '52:54:00:20:d3:33', ip => '10.32.23.254' }

  # TSE VM reservations (OPS-9172, OPS-10613, OPS-11474)
  dhcp::host { 'tse-puppetmaster2-prod': mac   => '00:50:56:9A:60:FA', ip => '10.32.76.2' }
  dhcp::host { 'tse-iaas2-prod':         mac   => '00:50:56:9a:c8:4d', ip => '10.32.76.30' }
  dhcp::host { 'tse-vro2-prod':          mac   => '00:50:56:9a:a8:69', ip => '10.32.76.31' }
  dhcp::host { 'tse-vra2-prod':          mac   => '00:50:56:9a:12:2d', ip => '10.32.76.135' }
  dhcp::host { 'pe-master-tsedemo-01':   mac   => '00:50:56:87:50:cd', ip => '10.32.76.82' }
  dhcp::host { 'cd4pe-tsedemo-01':       mac   => '00:50:56:87:62:0a', ip => '10.32.76.228' }

  # DIO-1430
  dhcp::host { 'cml2-controller':        mac   => '00:50:56:87:11:48', ip => '10.32.77.138' }

  # SE Demos (vRA 7.6)
  dhcp::host { 'vra-demo-pe-master':     mac   => '00:50:56:87:7b:13', ip => '10.32.76.54' }
  dhcp::host { 'vra-demo-iaas-win2016':  mac   => '00:50:56:87:13:30', ip => '10.32.76.173' }
  dhcp::host { 'vra-demo-portal':        mac   => '00:50:56:87:1c:65', ip => '10.32.76.170' }

  # QE Jenkins servers
  dhcp::host { 'jenkins-master-prod-1':                  mac => '00:50:56:8f:1b:5a', ip => '10.32.77.58' }
  dhcp::host { 'cinext-jenkinsmaster-kub-test-1':        mac => '00:50:56:87:d9:52', ip => '10.32.77.129' }
  dhcp::host { 'cinext-jenkinsmaster-enterprise-prod-1': mac => '00:50:56:8f:ae:7b', ip => '10.32.113.73' }
  dhcp::host { 'cinext-jenkinsmaster-staging-1':         mac => '00:50:56:87:c6:25', ip => '10.32.77.10'}
  dhcp::host { 'cinext-jenkinsmaster-test-1':            mac => '00:50:56:87:81:c6', ip => '10.32.77.11'}
  dhcp::host { 'cinext-jenkinsmaster-platform-prod-1':   mac => '00:50:56:87:10:d7', ip => '10.32.77.12'}
  dhcp::host { 'cinext-jenkinsmaster-enterprise-prod-2': mac => '00:50:56:87:00:f0', ip => '10.32.77.13'}
  dhcp::host { 'cinext-jenkinsmaster-pipeline-prod-1':   mac => '00:50:56:87:b2:80', ip => '10.32.77.14'}
  dhcp::host { 'cinext-jenkinsmaster-sre-prod-2':        mac => '00:50:56:87:b3:ab', ip => '10.32.77.15'}
  dhcp::host { 'cith-db-prod-1':                         mac => '00:50:56:ad:49:59', ip => '10.32.77.16'}

  # Installer & Management Team WSUS server
  dhcp::host { 'ci-wsus-prod-1':        mac => '00:50:56:87:19:92', ip => '10.32.77.59'}

  # Forge (HELP-16087)
  dhcp::host { 'forge-aio02-petest': mac => '00:50:56:87:af:f0', ip => '10.32.22.137'}
  dhcp::host { 'forge-ci-prod-1':    mac => '00:50:56:87:10:27', ip => '10.32.23.178'}

  # CD4PE Test Infrastructure
  dhcp::host { 'cdpe-github-enterprise-test-1'      : mac => '00:50:56:87:27:0b', ip => '10.32.77.165' }

  # Artifactory LB
  dhcp::host { 'artifactory-lb-prod-1'      : mac => '00:50:56:87:a0:54', ip => '10.32.77.50' }

  # Veeam
  dhcp::host { 'veeam-standin-prod-1':   mac => '00:50:56:87:70:83', ip => '10.32.22.230'}

  # Fixture PostGres 96
  dhcp::host { 'postgres-testfixture-pg96-prod-1':           mac => '00:50:56:87:02:e4', ip => '10.32.77.56'}

  # LDAP TestFixtures
  dhcp::host { 'ldap-testfixture-prod-1': mac  => '00:50:56:87:14:a0', ip => '10.32.77.8'}
  dhcp::host { 'ldap-testfixture-prod-2': mac  => '00:50:56:87:5c:38', ip => '10.32.77.9'}

  # Redis
  dhcp::host { 'ci-getpe-prod-1': mac  => '00:50:56:87:c7:2b', ip => '10.32.77.7'}

  # Windows TestFixtures
  dhcp::host { 'valley': mac   => '00:50:56:8f:f8:ca', ip => '10.32.77.17'}
  dhcp::host { 'volcano': mac  => '00:50:56:8f:a1:c5', ip => '10.32.77.18'}
}
