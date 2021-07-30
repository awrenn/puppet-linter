# Manage the installation of some pacakges that the Operations team uses.
class profile::sysop {

  include profile::packages::shells

  include xz
  include curl

  unless $facts['kernel'] == 'Darwin' {
    include vim
  }

  $linux_packages_we_like = [
    'iftop',
    'iotop',
    'lsof',
    'mlocate',
    'nmap',
    'rsync',
    'screen',
    'tcpdump',
    'unzip',
    'wget',
  ]

  # Keeping the Linux kernel confinement here incase we ever do kfreebsd
  if $::kernel == 'Linux' {
    if $facts['os']['family'] == 'Debian' {
      # https://packages.debian.org/search?keywords=ack-grep&searchon=names&suite=all&section=all
      $deb_ack_package = $facts['os']['release']['major'] ? {
        '10' => 'ack',
        '9'  => 'ack',
        default => 'ack-grep',
      }

      $debian_packages_we_like = [
        $deb_ack_package,
        'dstat',
        'dnsutils',
        'htop',
        'net-tools',
        'psmisc',
        'pv',
        'strace',
        'tmux',
      ]

      $packages_to_install = $linux_packages_we_like + $debian_packages_we_like
    } elsif $facts['os']['family'] == 'Redhat' {
      Package { require => Class['epel'] }

      $redhat_packages_we_like = [
        'ack',
        'bind-utils',
        'dstat',
        'htop',
        'strace',
        'tmux',
      ]

      $packages_to_install = $linux_packages_we_like + $redhat_packages_we_like
    } elsif $facts['os']['family'] == 'Suse' {
      $stock_suse_packages = [
        'bind-utils',
        'less',
        'psmisc',
      ]

      $packages_to_install = $linux_packages_we_like + $stock_suse_packages
    } else {
      $packages_to_install = $linux_packages_we_like
    }

    ensure_packages($packages_to_install, {'ensure' => 'latest'})
  }

  # This was only being used by site/puppetlabs/manifests/service/pkgrepo.pp
  # gpg stuff has been moved to its own module; if gpg-agent should be part of
  # this package loadout then you should do 'include gpg'
  #@package { "gnupg-agent": ensure => installed; }

  # OS specific/named specific packages.
  case $facts['os']['name'] {
    'debian': {
      package { [ 'locales-all' ]:
        ensure => installed,
      }
    }
    'centos': {
      # package{ debian : ensure => reboot_and_install }
    }
  }
}
