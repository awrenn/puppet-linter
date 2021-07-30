# Class: profile::waylon
#
class profile::waylon (
  Boolean $install_from_git = false,
  Optional[String[1]] $git_repo = undef,
  Optional[String[1]] $git_ref = undef,
  ) {
  profile_metadata::service { $title:
    human_name => 'Waylon CI radiator',
    team       => 'dio',
  }

  meta_motd::fragment { 'EoL Notice':
    content => 'INFC-19256 tracks the likely EoL of this system',
  }

  include waylon::params


  $rbenv_install_path = hiera('profile::waylon::rbenv_install_path', $::waylon::params::rbenv_install_path)
  $ruby_version       = hiera('profile::waylon::ruby_version', $::waylon::params::ruby_version)
  $unicorn_version    = hiera('profile::waylon::unicorn_version', $::waylon::params::unicorn_version)
  $waylon_version     = hiera('profile::waylon::waylon_version', $::waylon::params::waylon_version)

  # Up to this point, we only supported running on Debian 7 "Wheezy".
  if $facts['os']['distro']['codename'] == 'wheezy' {
    include git
  }
  else {
    #the ::git class didn't work on centos
    package { 'git': ensure => present, }
  }

  anchor { 'waylon::begin': }
  anchor { 'waylon::end': }

  class { '::waylon::install':
    rbenv_install_path => $rbenv_install_path,
    ruby_version       => $ruby_version,
    unicorn_version    => $unicorn_version,
    waylon_version     => $waylon_version,
    manage_deps        => false,
    require            => Anchor['waylon::begin'],
    before             => Class['waylon::config'],
  }

  if $install_from_git {
    $app_root = '/var/lib/waylon/'

    vcsrepo { $app_root:
      ensure   => present,
      provider => 'git',
      source   => $git_repo,
      revision => $git_ref,
      require  => Anchor['waylon::begin'],
      before   => Class['waylon::config'],
    }
    -> exec { 'bundle the app':
      command => '/usr/local/rbenv/shims/bundle install',
      user    => 'root',
      cwd     => $app_root,
      require => Class['waylon::install'],
    }
  } else {
    $app_root = "${rbenv_install_path}/versions/${ruby_version}/lib/ruby/gems/2.1.0/gems/waylon-${waylon_version}"
  }

  class { '::waylon::config':
    app_root          => $app_root,
    refresh_interval  => hiera('profile::waylon::config::refresh_interval', $::waylon::params::refresh_interval),
    trouble_threshold => hiera('profile::waylon::config::trouble_threshold', $::waylon::params::trouble_threshold),
    views             => hiera('profile::waylon::config::views'),
    before            => Class['waylon::memcached'],
  }

  class { '::waylon::memcached':
    before => Class['waylon::unicorn'],
  }

  class { '::waylon::unicorn':
    app_root           => $app_root,
    rbenv_install_path => $rbenv_install_path,
    ruby_version       => $ruby_version,
    before             => Class['waylon::nginx'],
  }

  class { '::waylon::nginx':
    app_root => $app_root,
    before   => Anchor['waylon::end'],
  }


  logrotate::job { 'rotate-waylon-stdout':
    log     => '/var/log/waylon/waylon.out',
    options => [
      'daily',
      'rotate 7',
      'copytruncate',
      'missingok',
      'compress',
      'delaycompress',
      'notifempty',
    ],
    require => Anchor['waylon::end'],
  }

  logrotate::job { 'rotate-waylon-stderr':
    log     => '/var/log/waylon/waylon.err',
    options => [
      'daily',
      'rotate 7',
      'copytruncate',
      'missingok',
      'compress',
      'delaycompress',
      'notifempty',
    ],
    require => Anchor['waylon::end'],
  }
}
