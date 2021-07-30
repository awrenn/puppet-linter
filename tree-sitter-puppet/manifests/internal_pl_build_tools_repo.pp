class profile::internal_pl_build_tools_repo {
  case $facts['os']['family'] {
    'debian': {
      apt::source { 'internal-pl-build-tools-repo':
        ensure   => present,
        location => 'http://pl-build-tools.delivery.puppetlabs.net/debian',
        repos    => 'main',
        key      => {
          'id'     => '27D8D6F1', # 27D8D6F1 is an internal RE key with email pluto@puppetlabs.lan
          'source' => 'http://pl-build-tools.delivery.puppetlabs.net/debian/DEB-GPG-KEY-pluto',
        },
        pin      => '901',
      }

      apt::key { 'puppet gpg key':
        id     => '6F6B15509CF8E59E6E469F327F438280EF8D349F',
        source => 'http://pl-build-tools.delivery.puppetlabs.net/debian/DEB-GPG-KEY-puppet',
      }

      apt::key { 'puppetlabs gpg key':
        id     => '47B320EB4C7C375AA9DAE1A01054B7A24BD6EC30',
        source => 'http://pl-build-tools.delivery.puppetlabs.net/debian/DEB-GPG-KEY-puppetlabs',
      }
      apt::key { 'puppet gpg key 2025-04-06':
        id     => 'D6811ED3ADEEB8441AF5AA8F4528B6CD9E61EF26',
        source => 'http://pl-build-tools.delivery.puppetlabs.net/debian/DEB-GPG-KEY-puppet-20250406',
      }
    }

    'redhat': {
      if $facts['os']['name'] == 'Fedora' {
        $os_prefix = 'f'
        $os = 'fedora'
      } else {
        $os_prefix = ''
        $os = 'el'
      }

      yumrepo { 'internal-pl-build-tools-repo':
        descr   => 'internal-pl-build-tools-repo',
        baseurl => "http://pl-build-tools.delivery.puppetlabs.net/yum/${os}/${os_prefix}${facts['os']['release']['major']}/\$basearch",
        enabled => '1',
      }
    }

    default: { notify { "OS ${osfamily} has no love": } }
  }
}
