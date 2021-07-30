# Class: profile::jenkins::usage::java11
# Sets up java11 for Jenkins on Centos7
#
class profile::jenkins::usage::java11 {
  profile_metadata::service { $title:
    human_name => 'Java 11 build tools for Jenkins',
    team       => 'dio',
    doc_urls   => [
      'https://confluence.puppetlabs.com/display/SRE/Jenkins+Instances',
      'https://plugins.jenkins.io/swarm',
    ],
  }

  # OpenJDK 7 is already managed by the Jenkins module.
  # ::jenkins::install_java or ::jenkins::slave::install_java should be false to use this profile
  # this can be set through the class parameter $intall_jenkins_java
  case $facts['os']['name'] {
    'centos': {
      class { 'java':
        distribution => 'jdk',
        package      => 'java-11-openjdk-devel',
        version      => '11.0.5.10-0.el7_7',
      }
    }
    default: {
      notify { "profile::jenkins::usage::java11 cannot set up JDK on ${facts['os']['name']}": }
    }
  }
}
