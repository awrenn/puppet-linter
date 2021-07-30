# Sets up our custom nodejs/npm packages.
class profile::nodejs (
  Optional[String[1]] $package_version = 'latest',
  Optional[String[1]] $npm_package = 'present',
  String[1] $deb_node_source = 'https://deb.nodesource.com/node_4.x',
) {
  class { '::nodejs':
    nodejs_package_ensure     => $package_version,
    npm_package_ensure        => $npm_package,
    nodejs_dev_package_ensure => $facts['os']['family'] ? {
      'Debian' => false,
      default  => present,
    },
    manage_package_repo       => $facts['os']['family'] ? {
      'Debian' => false,
      default  => true,
    },
  }
  contain ::nodejs

  if $facts['os']['family'] == 'Debian' {
    apt::source { 'nodesource':
      location => $deb_node_source,
      release  => $facts['os']['distro']['codename'],
      repos    => 'main',
      key      => {
        id     => '9FD3B784BC1C6FC31A8A0A1C1655A0AB68576280',
        server => 'keys.gnupg.net',
      },
    }

    Apt::Source['nodesource'] -> Class['::nodejs']
  }
}
