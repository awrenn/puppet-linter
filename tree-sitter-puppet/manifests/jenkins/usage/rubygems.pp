# Class: profile::jenkins::usage::rubygems
#

class profile::jenkins::usage::rubygems (
  String $rubygems_api_key,
  String $artifactory_api_key,
) {
  file { "${::profile::jenkins::params::agent_home}/.gem":
    ensure => directory,
    owner  => $::profile::jenkins::params::jenkins_owner,
    group  => $::profile::jenkins::params::jenkins_group,
  }

  file { "${::profile::jenkins::params::agent_home}/.gem/credentials":
    ensure  => file,
    owner   => $::profile::jenkins::params::jenkins_owner,
    group   => $::profile::jenkins::params::jenkins_group,
    mode    => '0600',
    require => File["${::profile::jenkins::params::agent_home}/.gem"],
    content => template('profile/jenkins/agent/rubygems/credentials.erb'),
  }
}
