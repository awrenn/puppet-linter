class profile::jruby (
  $ensure = installed
) {
  include profile::internal_pl_build_tools_repo

  package { 'pl-jruby':
    ensure => $ensure,
  }

  file { '/usr/bin/jruby':
    ensure  => link,
    target  => '/usr/local/share/pl-jruby/bin/jruby',
    require => Package[ 'pl-jruby' ],
  }

  file { '/usr/bin/jgem':
    ensure  => link,
    target  => '/usr/local/share/pl-jruby/bin/jgem',
    require => Package[ 'pl-jruby' ],
  }

}
