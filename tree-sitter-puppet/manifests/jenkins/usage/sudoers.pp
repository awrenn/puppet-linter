# Class: profile::jenkins::usage::sudoers
#

class profile::jenkins::usage::sudoers {

  include profile::jenkins::params

  # Bring variables in-scope to improve readability
  $agent_home  = $::profile::jenkins::params::agent_home

  file { "${agent_home}/sudoers.d":
    ensure  => directory,
    source  => 'puppet:///modules/profile/jenkins/agent/sudoers.d',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => true,
    purge   => true,
  }
}
