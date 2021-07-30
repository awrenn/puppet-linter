# Class: profile::os::linux::debian::vanilla
#
# Add apt sources and include modules specific to Debian
#
class profile::os::linux::debian::vanilla {
  include apt::backports

  if Integer($facts['os']['release']['major']) >= 8 {
    include profile::os::linux::systemd
  }

  apt::source { 'main':
    location => hiera('profile::os::linux::debian::vanilla::main_apturl'),
    repos    => 'main contrib non-free',
  }
  apt::source { 'security':
    location => hiera('profile::os::linux::debian::vanilla::sec_apturl'),
    release  => "${facts['os']['distro']['codename']}/updates",
    repos    => 'main contrib non-free',
  }

  # Add squeeze-lts for squeeze boxes
  if $facts['os']['distro']['codename'] == 'squeeze' {
    apt::source { 'squeeze-lts':
      location => hiera('profile::os::linux::debian::vanilla::main_apturl'),
      release  => 'squeeze-lts',
      repos    => 'main contrib non-free',
    }
  }
  elsif $facts['os']['distro']['codename'] == 'jessie' {
    #Note: This is generally a bad idea, but jessie-backports isn't receiving
    #      Release file updates and jessie doesn't support disabling this per
    #      repo
    apt::conf { 'no-check-valid-until':
      priority => 99,
      content  => 'Acquire::Check-Valid-Until no;',
    }
  }
  elsif $facts['os']['distro']['codename'] == 'stretch' {
    # Just think of all the cool stuff we can add here later
  }
  else {
    include recap
  }

  $_release = $facts['os']['distro']['codename'] ? {
    'jessie' => 'wheezy',
    default  => $facts['os']['distro']['codename'],
  }

  # Add Plops s3 repo configuration...but we only have packages published
  # to squeeze so this breaks jessie.
  apt::source { 's3-debrepo':
    ensure   => 'absent',
    location => 'http://plops-debrepo.s3.amazonaws.com',
    release  => $_release,
    include  => {
      'src' => false,
    },
  }

  apt::key { 's3-gpg-key':
    ensure => 'absent',
    id     => 'D36634C186B8C070036E3D5AD5BF173D83960711',
    source => 'http://plops-debrepo.s3.amazonaws.com/plops.gpg.key',
  }

  # Let's not use opsapt on Debian 9 (Stretch) and newer...
  unless $facts['os']['name'] == 'Debian' and Integer($facts['os']['release']['major']) >= 9 {
    include profile::repos::opsapt
  }
}
