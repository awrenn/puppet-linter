# Used on nodes connected to Platform9
class profile::p9openstack::common (
  String[1] $region,
) {
  include profile::nfs::client
  include selinux

  yumrepo { 'centos-qemu-ev':
    ensure   => 'present',
    baseurl  => 'http://mirror.centos.org/centos/$releasever/virt/$basearch/kvm-common/',
    descr    => 'CentOS-$releasever - QEMU EV',
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization',
  }

  # Needed for python-openstackclient
  ensure_packages(['gcc'])

  service { 'firewalld':
    ensure => stopped,
    enable => false,
  }

  realize Account::User['pf9']

  # For live migrations and ARS mode (remote support)
  ssh::allowgroup { 'pf9group': }

  # They often need full sudo to use ARS.
  sudo::allowgroup { 'pf9group': }

  file {
    default:
      ensure => directory,
      owner  => 'pf9',
      group  => 'pf9group',
      mode   => '0755',
    ;
    '/var/log/pf9': ;
    '/var/log/pf9/comms': ;
    '/var/log/pf9/sidekick': ;
    '/var/opt/pf9': ;
    '/opt/pf9': ;
    '/opt/pf9/etc': ;
  }

  file { '/root/platform9-install-redhat.sh':
    source => "https://artifactory.delivery.puppetlabs.net/artifactory/generic__local/infracore/platform9/platform9-install-${region}-redhat.sh",
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  $log_files = [
    '/var/log/pf9/pf9-neutron-dhcp-agent.log',
    '/var/log/pf9/pf9-neutron-l3-agent.log',
    '/var/log/pf9/pf9-neutron-metadata-agent.log',
    '/var/log/pf9/pf9-neutron-ovs-agent.log',
  ]

  $log_files.each | $log_file | {
    file { $log_file.regsubst('/var/log/pf9', '/etc/logrotate.d', 'G').regsubst('\\.log', '.conf', 'G'):
      content => epp('profile/p9openstack/logrotate.conf.epp',
        { 'log_file' => $log_file } ),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  }

  exec { 'install platform9':
    command   => '/root/platform9-install-redhat.sh --no-proxy --no-ntpd --skip-os-check',
    path      => '/usr/bin:/usr/sbin:/bin:/sbin',
    unless    => 'rpm -q pf9-hostagent',
    require   => File['/opt/pf9/home'],
    subscribe => File['/root/platform9-install-redhat.sh'],
  }

  service { ['pf9-hostagent', 'pf9-comms', 'pf9-sidekick']:
    ensure    => running,
    enable    => true,
    subscribe => Exec['install platform9'],
  }
}
