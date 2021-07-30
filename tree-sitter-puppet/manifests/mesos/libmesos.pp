# Class: profile::mesos::libmesos
#
class profile::mesos::libmesos {

  case $facts['os']['name'] {
    'debian': {
      apt::source { 'cinext_apt_source':
        comment  => 'internal-tools repo',
        location => 'https://internal-tools.delivery.puppetlabs.net/debian',
        release  => 'wheezy',
        repos    => 'main',
        pin      => '-10',
        include  => {
          'deb' => true,
        },
      }

      $ensure = '1.2.0-1wheezy'

      package { 'pl-mesos-lib':
        ensure  => $ensure,
        require => Apt::Source['cinext_apt_source'],
      }
    }
    'centos': {
      yumrepo { 'internal-tools-repo':
        descr   => 'internal-tools-repo',
        baseurl => "http://internal-tools.delivery.puppetlabs.net/yum/el/${facts['os']['release']['major']}/\$basearch",
        enabled => '1',
      }

      $ensure = '1.2.0-5.el7.x86_64'

      package { 'pl-mesos-lib':
        ensure  => $ensure,
        require => Yumrepo['internal-tools-repo'],
      }
    }
    default: { notify { "No internal tools repo for ${$facts['os']['name']}": } }
  }
}
