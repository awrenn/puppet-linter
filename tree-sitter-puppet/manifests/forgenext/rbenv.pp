# This class manages rbenv
# this is used on the app servers in order to run forge-web and forge-api under
# ruby 1.9.3-p194, and on the util / anubis servers to run compatibility tests
# for multiple rubies.
#
# the app servers only need one version installed, and it's much faster to
# build if only one version is installed.
#
class profile::forgenext::rbenv (
  Array[String[1]] $ruby_versions = [ '2.2.5', '2.1.6', '1.9.3-p194', '1.8.7-p375' ]
) {

  include git

  $base_package_list = [
    'autoconf',
    'bison',
    'build-essential',
    'libssl-dev',
    'libyaml-dev',
    'libreadline-dev',
    'zlib1g-dev',
    'libncurses5-dev',
    'libffi-dev',
    'libgdbm-dev',
    'libdb-dev',
  ]

  $os_package_list = $facts['os']['release']['major'] ? {
    '8'     => [ 'libgdbm3', 'libreadline6-dev' ],
    default => [ 'libgdbm6' ],
  }

  $ruby_version_package_list = $ruby_versions.any |$ver| { $ver =~ /^1\.8\.7/ } ? {
    true  => [ 'subversion' ],
    false => [],
  }

  $package_list = $base_package_list + $os_package_list + $ruby_version_package_list

  package { $package_list: } -> rbenv::build { $ruby_versions: }

  class { '::rbenv':
    manage_deps => false,
  }

  rbenv::plugin { [ 'sstephenson/rbenv-vars', 'sstephenson/ruby-build' ]: }
}
