# Class: profile::jenkins::params
# These parameters are used throughout profile::jenkins.
#
class profile::jenkins::params (
  $agent_version = '2.0',
  $client_jar    = 'swarm-client-2.0-jar-with-dependencies.jar',
  ) {

  # General-use default params
  $jenkins_owner = 'jenkins'
  $jenkins_group = $facts['os']['family'] ? {
    'darwin'  => 'staff',
    'windows' => 'Administrators',
    default   => 'jenkins',
  }

  # Params related to managing masters
  $master_config_dir = '/var/lib/jenkins'

  $agent_home = $::kernel ? {
    'darwin'  => '/Users/jenkins',
    'linux'   => '/var/lib/jenkins',
    'windows' => 'C:/jenkins',  # (QENG-1162) drive letter must be uppercase
    default   => '/var/lib/jenkins',
  }

  # Jenkins swarm-client download URL and filename for non-Linux agents
  # the new URL was changed here https://github.com/jenkinsci/puppet-jenkins/commit/cb458643fe9adebd3d8e7c8a54865c48db64fbf9
  $client_url = "https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${agent_version}/"
}
