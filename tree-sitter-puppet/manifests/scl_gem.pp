# this is a modified version of
# https://github.com/covermymeds/puppet-ruby/blob/master/manifests/gem.pp
#
# == Define: scl_gem
#
# This defined type installs a gem into a specific SCL version of Ruby.
# Note that the name of this resource is expected to be in the form
# "rubyver_gem", so that we can install multiple gems into multiple
# Software Collections Rubies.
#
# === Parameters
#
# version: the version to install. Mandatory.
# options: installation options.
#
# === Examples
#
# === Authors
#
# Scott Merrill <smerrill@covermymeds.com>
#
# === Copyright
#
# Copyright 2014, CoverMyMeds unless otherwise noted
#
define profile::scl_gem (
  Enum['latest', 'present', 'absent'] $ensure = 'present',
  $ri      = false,
  $rdoc    = false,
  $options = undef,
  $version = undef,
) {

  if $ri {
    $_ri = '--ri'
  } else {
    $_ri = '--no-ri'
  }

  if $rdoc {
    $_rdoc = '--rdoc'
  } else {
    $_rdoc = '--no-rdoc'
  }

  # the $name value of this defined type is expected to come through
  # with the SCL Ruby version prefixed to the gem name. We'll need to split it.
  $gemdata = split($name, '_')
  $ruby = $gemdata[0]
  $gem = regsubst($name, "^${ruby}_(.+)", '\1')
  if empty($gem) {
    fail('The gem name could not be distinguished from the ruby version')
  }

  if $version {
    $_v = "--version ${version}"
  } else {
    $_v = ''
  }

  $default_options = "${_ri} ${_rdoc}"
  # we have a specific set of options required, but additional options
  # can be specified
  if $options {
    $_o = join( [$default_options, $options], ' ' )
  } else {
    $_o = $default_options
  }

  case $ensure {
    'present': {
      exec { "install gem ${gem} for ${ruby}":
        command => "/usr/bin/scl enable ${ruby} 'gem install ${gem} ${_v} ${_o}'",
        unless  => "/usr/bin/scl enable ${ruby} 'gem list -i -l ${_v} ${gem}'",
      }
    }
    'absent': {
      exec { "install gem ${gem} for ${ruby}":
        command => "/usr/bin/scl enable ${ruby} 'gem uninstall ${gem} ${_v}'",
        unless  => "! /usr/bin/scl enable ${ruby} 'gem list -i -l ${_v} ${gem}'",
      }
    }
    'latest': {
      exec { "update gem ${gem} for ${ruby}":
        path    => '/usr/local/bin:/usr/bin',
        command => "/usr/bin/scl enable ${ruby} 'gem update ${gem}'",
        unless  => "[ \"$(/usr/bin/scl enable ${ruby} 'gem outdated' |/usr/bin/grep ${gem} -c)\" -eq \"0\" ]",
      }
    }
  }
}

