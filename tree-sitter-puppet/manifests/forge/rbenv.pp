# This class manages rbenv. targetted at anubis now
class profile::forge::rbenv {

  # rbenv sometimes forgets to remove this lock file
  file { '/usr/local/rbenv/shims/.rbenv-shim':
    ensure => absent,
  }

  package { [
    'autoconf',
    'bison',
    'libyaml-dev',
    'libncurses5-dev',
    'libffi-dev',
    'libgdbm-dev',
    'build-essential',
    'libssl-dev',
    'libreadline6-dev',
    'zlib1g-dev',
    'libgdbm3',
  ]: } -> rbenv::build { [ '2.5.1', '2.4.4', '2.3.1', '2.1.9' ]: }
  class { '::rbenv':
    manage_deps => false,
  }
  rbenv::plugin { [ 'sstephenson/rbenv-vars', 'sstephenson/ruby-build' ]: }
}
