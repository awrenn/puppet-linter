# Class: profile::jenkins::usage::java8
# Sets up java8 for Jenkins on Debian
#
class profile::jenkins::usage::java8 {
  profile_metadata::service { $title:
    human_name => 'Java 8 build tools for Jenkins',
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
    'debian': {
      class { 'java':
        distribution => 'oracle-jdk8',
        version      => '8u102',
      }

      package { 'tzdata-java':
        ensure => latest,
      }
    }
    'centos': {
      class { 'java':
        distribution => 'jdk',
        package      => 'java-1.8.0-openjdk-devel',
        version      => '1.8.0.222.b10-0.el7_6',
      }
    }
    default: {
      notify { "profile::jenkins::usage::java8 cannot set up JDK on ${facts['os']['name']}": }
    }
  }
}
