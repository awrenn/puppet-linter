# Class: profile::jenkins::agent::darwin::service
# Install a PL approved Jenkins agent running on Darwin (Mac OS X).
# This has been tested on OS X 10.8.
#
# Parts of this class (esp. the launchd bits) were originally written
# by Jeff McCune in `puppetlabs-modules` and have since been heavily
# modified to use the Swarm client on OS X.
#
class profile::jenkins::agent::darwin::service {
  include profile::jenkins::params
  include profile::jenkins::agent

  # Bring variables in-scope to improve readability
  $master_url    = $::profile::jenkins::agent::master_url
  $master_user   = $::profile::jenkins::agent::master_user
  $master_pass   = unwrap(lookup('profile::jenkins::agent::sensitive_master_pass'))
  $executors     = $::profile::jenkins::agent::executors
  $labels        = $::profile::jenkins::agent::labels
  $agent_alias   = $::profile::jenkins::agent::agent_alias
  $client_url    = $::profile::jenkins::params::client_url
  $client_jar    = $::profile::jenkins::params::client_jar
  $jenkins_owner = $::profile::jenkins::params::jenkins_owner
  $jenkins_group = $::profile::jenkins::params::jenkins_group
  $agent_home    = $::profile::jenkins::params::agent_home

  # Download Swarm client
  exec { 'download-swarm-client':
    path    => '/usr/bin',
    command => "curl -o ${agent_home}/${client_jar} ${client_url}/${client_jar}",
    creates => "${agent_home}/${client_jar}",
    require => Class['profile::jenkins::agent::darwin'],
  }

  file { '/var/log/jenkins':
    ensure  => directory,
    owner   => $jenkins_owner,
    group   => $jenkins_group,
    mode    => '0775',
    require => Class['profile::jenkins::agent::darwin'],
  }

  # A mess of arguments to pass to the service template.
  $client_jar_flag = "-jar ${agent_home}/${client_jar}"
  $mode_flag       = '-mode normal'
  $fs_root_flag    = "-fsroot ${agent_home}"

  if $executors {
    $executors_flag = "-executors ${executors}"
  }
  else {
    $executors_flag = ''
  }

  if $master_user {
    $ui_user_flag = "-username ${master_user}"
  }
  else {
    $ui_user_flag = ''
  }

  if $master_pass {
    $ui_pass_flag = "-password ${master_pass}"
  }
  else {
    $ui_pass_flag = ''
  }

  if $agent_alias != 'undef' {
    $agent_alias_flag = "-name ${agent_alias}"
  }
  else {
    $agent_alias_flag = ''
  }

  if $master_url {
    $master_url_flag = "-master ${master_url}"
  }
  else {
    $master_url_flag = ''
  }

  if $labels {
    $labels_flag = "-labels \"${labels}\""
  }
  else {
    $labels_flag = ''
  }

  # Manage the files needed for launchd (script and plist)
  file { "${agent_home}/slave.swarm.sh":
    owner   => $jenkins_owner,
    group   => $jenkins_group,
    mode    => '0755',
    content => template('profile/jenkins/swarm-darwin.sh.erb'),
  }

  file { '/Library/LaunchDaemons/org.jenkins-ci.slave.swarm.plist':
    owner   => 'root',
    group   => 'wheel',
    mode    => '0644',
    content => template('profile/jenkins/swarm-darwin.plist.erb'),
    require => [
      File['/var/log/jenkins'],
      File["${agent_home}/slave.swarm.sh"],
    ],
  }

  # Before trying to load the service, we need to set a hosts file entry.
  # Without this, Java _will_ throw a `java.net.UnknownHostException` exception
  # but launchd will report the service as 'running'
  host { $facts['networking']['fqdn']:
    ensure       => present,
    host_aliases => $facts['networking']['hostname'],
    ip           => $facts['networking']['ip'],
  }

  # Launchctl, load me this Jenkins!
  service { 'org.jenkins-ci.slave.swarm':
    ensure  => running,
    enable  => true,
    require => [
      Host[$facts['networking']['fqdn']],
      File['/Library/LaunchDaemons/org.jenkins-ci.slave.swarm.plist'],
    ],
  }
}
