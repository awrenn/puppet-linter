class profile::internal_tools_repo {
  case $facts['os']['family'] {
    'debian': {
      apt::source { 'internal-tools-repo':
        ensure   => present,
        location => 'http://internal-tools.delivery.puppetlabs.net/debian',
        repos    => 'main',
        pin      => '901',
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

      yumrepo { 'internal-tools-repo':
        descr   => 'internal-tools-repo',
        baseurl => "http://internal-tools.delivery.puppetlabs.net/yum/${os}/${os_prefix}${facts['os']['release']['major']}/\$basearch",
        enabled => '1',
      }
    }

    default: { notify { "No internal tools repo for ${osfamily}": } }
  }
}
