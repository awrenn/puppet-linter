# site/profile/manifests/os/linux/debian/cumuluslinux.pp
class profile::os::linux::debian::cumuluslinux {

  # This is needed to be compatible with Facter 2.x
  $distro = $facts['os']['distro']
  if !$distro {
    $release = $facts['os']['release']
  } else {
    $release = $facts['os']['distro']['release']
  }

  if (versioncmp($release['major'], '3') < 0) {
    # This gets us the x.y cumulus release used by apt, for example: CumulusLinux-2.5
    $cumulus_release = "${facts['os']['name']}-${release['major']}.${release['minor']}"

    ##
    # APT - Repository Management
    #

    # Cumulus Linux primary repos
    apt::source { 'cumulus':
      location => 'http://repo.cumulusnetworks.com',
      release  => "${cumulus_release}",
      repos    => 'main addons updates',
    }

    # Cumulus Linux security updates repo
    apt::source { 'cumulus_security_updates':
      location => 'http://repo.cumulusnetworks.com',
      release  => "${cumulus_release}",
      repos    => 'security-updates',
    }

    # PuppetLabs cumulus agent repo
    apt::source { 'cumulus_puppetlabs_agent':
      location => 'http://apt.puppetlabs.com',
      release  => 'cumulus',
      repos    => 'PC1',
    }

    # Debian primary repo for packages not provided by Cumulus repo
    apt::source { 'debian_wheezy':
      location => hiera('profile::os::linux::debian::vanilla::main_apturl'),
      repos    => 'main contrib non-free',
      pin      => 300,
    }

    # Debian wheey backports
    apt::source { 'debian_wheezy_backports':
      location => hiera('profile::os::linux::debian::vanilla::main_apturl'),
      release  => 'wheezy-backports',
      repos    => 'main contrib non-free',
      pin      => 301,
    }

    ##
    # Manage the cumulus puppet AIO package and Debian PPA.
    #
    package { 'puppetlabs-release-pc1':
      ensure => latest,
    }

    package { 'puppet-agent':
      ensure  => latest,
      require => Package['puppetlabs-release-pc1'],
    }

    ##
    # Install netshow tool
    #
    package { 'netshow':
      ensure => latest,
    }

    ##
    # Used by interfaces when changes are made.
    # Reloads all auto interfaces.
    #
    exec { 'ifreload-all':
      command     => '/sbin/ifreload -a',
      refreshonly => true,
    }

    ##
    # Kill user 'cumulus' processes so user can be removed.
    #
    exec { 'kill-cumulus-user-procs':
      command     => '/usr/bin/pkill -9 -u cumulus',
      onlyif      => '/usr/bin/pgrep -u cumulus',
      refreshonly => true,
    }

    ##
    # Remove 'cumulus' user
    #
    user { 'cumulus':
      ensure     => absent,
      managehome => true,
      require    => Exec['kill-cumulus-user-procs'],
    }
  } else {
    # This gets us the x.y cumulus release used by apt, for example: CumulusLinux-3
    $cumulus_release = "${facts['os']['name']}-${release['major']}"

    ##
    # APT - Repository Management
    #

    # Cumulus Linux primary repos
    apt::source { 'cumulus':
      location => 'http://repo3.cumulusnetworks.com/repo',
      release  => "${cumulus_release}",
      repos    => 'cumulus upstream',
      include  => {
        'src' => true,
        'deb' => true,
      },
    }

    # Cumulus Linux security repos
    apt::source { 'cumulus-security-updates':
      location => 'http://repo3.cumulusnetworks.com/repo',
      release  => "${cumulus_release}-security-updates",
      repos    => 'cumulus upstream',
      include  => {
        'src' => true,
        'deb' => true,
      },
    }

    # Cumulus Linux updates repos
    apt::source { 'cumulus-updates':
      location => 'http://repo3.cumulusnetworks.com/repo',
      release  => "${cumulus_release}-updates",
      repos    => 'cumulus upstream',
      include  => {
        'src' => true,
        'deb' => true,
      },
    }

    # Debian Main repos
    apt::source { 'debian':
      location => 'http://httpredir.debian.org/debian',
      pin      => '300',
      release  => 'jessie',
      repos    => 'main contrib',
      include  => {
        'src' => true,
        'deb' => true,
      },
    }
  }
}
