# Class: profile::jenkins::agent::windows::service
# Downloads, installs, and manages the Jenkins Swarm Client service.
#
class profile::jenkins::agent::windows::service {
  include profile::jenkins::params
  include profile::jenkins::agent

  # Bring variables in-scope to improve readability
  $master_url           = $::profile::jenkins::agent::master_url
  $master_user          = $::profile::jenkins::agent::master_user
  $master_pass          = unwrap(lookup('profile::jenkins::agent::sensitive_master_pass'))
  $executors            = $::profile::jenkins::agent::executors
  $labels               = $::profile::jenkins::agent::labels
  $agent_alias          = $::profile::jenkins::agent::agent_alias
  $client_url           = $::profile::jenkins::params::client_url
  $client_jar           = $::profile::jenkins::params::client_jar
  $jenkins_owner        = $::profile::jenkins::params::jenkins_owner
  $jenkins_group        = $::profile::jenkins::params::jenkins_group
  $agent_home           = $::profile::jenkins::params::agent_home
  $install_agent_java11 = $::profile::jenkins::agent::install_agent_java11

  if $install_agent_java11 {
    windows_java::jdk {'8u144':
      build_number_hash => {
        '8u144' => 'b01',
        '8u45'  => 'b15',
        '8u40'  => 'b26',
        '8u31'  => 'b13',
        '8u25'  => 'b18',
        '8u20'  => 'b26',
        '8u11'  => 'b12',
        '8u5'   => 'b13',
        '8'     => 'b132',
        '7u80'  => 'b15',
        '7u79'  => 'b15',
        '7u76'  => 'b13',
        '7u75'  => 'b13',
        '7u72'  => 'b14',
        '7u60'  => 'b19',
        '7u51'  => 'b13',
        '7u45'  => 'b18',
        '7u25'  => 'b17',
      },
      #from https://lv.binarybabel.org/catalog/java/jdk8
      source            => 'http://download.oracle.com/otn-pub/java/jdk/8u144-b01/090f390dda5b47b9b721c7dfaa008135/jdk-8u144-windows-x64.exe',
    }
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

  if $agent_alias {
    $agent_alias_flag = "-name ${agent_alias}"
  }
  else {
    $agent_alias_flag = "-name ${facts['networking']['fqdn']}"
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

  # Download and manage the Swarm client JAR.
  # For Windows, there is already a path param passed to the exec resource
  # default in profile::os::windows.
  #
  # NOTE: As of Puppet 3.7, the 'exec' resource cannot execute commands on
  # behalf of other users. So we need to download the swarm-client JAR, *then*
  # manage its ownership and permissions. See PUP-532 for more information.
  exec { 'download-swarm-client':
    command => "wget.exe -O ${agent_home}/${client_jar} ${client_url}/${client_jar}",
    path    => "c:/programdata/chocolatey/bin;${::path}",
    creates => "${agent_home}/${client_jar}",
    notify  => Exec['uninstall-jenkins-service'],
    require => Class['profile::jenkins::agent::windows'],
  }
  file { "${agent_home}/${client_jar}":
    ensure  => file,
    owner   => $jenkins_owner,
    group   => 'S-1-5-32-544',  # Administrators
    mode    => '0775',
    require => Exec['download-swarm-client'],
  }

  # Let's install the service.
  file { "${agent_home}/swarm-client.xml":
    content => template('profile/jenkins/swarm-client-win.xml.erb'),
    notify  => Exec['uninstall-jenkins-service'],
    require => User[$jenkins_owner],
  }

  file { "${agent_home}/swarm-client.exe.config":
    source  => 'puppet:///modules/profile/jenkins/swarm-client-win.config',
    notify  => Exec['uninstall-jenkins-service'],
    require => User[$jenkins_owner],
  }

  # Yes, this is a binary. It is required for running the JAR as a service,
  # _and_ it's only 37 KB. So don't panic. For more information on how
  # this works, see: https://github.com/kohsuke/winsw
  file { "${agent_home}/swarm-client.exe":
    source  => 'puppet:///modules/profile/jenkins/swarm-client-win.exe',
    notify  => Exec['uninstall-jenkins-service'],
    require => [
      File["${agent_home}/swarm-client.xml"],
      File["${agent_home}/swarm-client.exe.config"],
    ],
  }

  # For this to work correctly, the actual command must be wrapped in a
  # `cmd.exe` of its own. Thanks to Josh Cooper for pointing this out.
  # cmd.exe does not return %errorlevel% properly, so I'm piping it with FIND
  # to return 0 when it finds RUNNING, 1 otherwise
  exec { 'install-jenkins-service':
    path    => "c:/windows/system32;${agent_home}",
    command => "${agent_home}/swarm-client.exe install",
    unless  => 'cmd.exe /c sc.exe query jenkins-slave | FIND "RUNNING"',
    require => [
      Exec['download-swarm-client'],
      File["${agent_home}/swarm-client.exe"],
      Class['profile::jenkins::agent::windows'],
    ],
  }

  # Maintain an exec resource to stop and uninstall the jenkins-slave service,
  # allowing it to be "reinstalled" when the config files change.
  #
  # Allowed return coodes are 0 (successful) and 1 (not successful),
  # because this command may be run during initial provisioning when the
  # service doesn't yet exist on the system.
  exec { 'uninstall-jenkins-service':
    path        => "c:/windows/system32;${agent_home}",
    command     => 'net stop jenkins-slave & sc.exe delete jenkins-slave',
    refreshonly => true,
    returns     => [0, 1],
    notify      => Exec['install-jenkins-service'],
    logoutput   => true,
  }

  # Last but not least, manage the installed service.
  service { 'jenkins-slave':
    ensure  => running,
    enable  => true,
    require => Exec['install-jenkins-service'],
  }
}
