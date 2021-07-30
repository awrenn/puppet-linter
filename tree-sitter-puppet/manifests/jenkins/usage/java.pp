# Class: profile::jenkins::usage::java
#
class profile::jenkins::usage::java {
  profile_metadata::service { $title:
    human_name => 'Java build tools for Jenkins',
    team       => 'dio',
    doc_urls   => [
      'https://confluence.puppetlabs.com/display/SRE/Jenkins+Instances',
      'https://plugins.jenkins.io/swarm',
    ],
  }

  include profile::jenkins::params

  # Bring variables in-scope to improve readability
  $jenkins_home  = $::profile::jenkins::params::agent_home
  $jenkins_owner = $::profile::jenkins::params::jenkins_owner
  $jenkins_group = $::profile::jenkins::params::jenkins_group

  Exec { path => '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin' }

  # OpenJDK 7 is already managed by the Jenkins module.
  # Here are some additional JDKs, based on OS family.
  case $facts['os']['family'] {
    'debian': {
      include profile::apt

      # removed oracle java 8 since the licensing starting April 2019 makes it impossible to continue

      if $facts['os']['distro']['codename'] == 'jessie' {
        $ca_certs_java_version = '20161107~bpo8+1'
        package { "ca-certificates-java=${ca_certs_java_version}":
          ensure => installed,
          before => Package['openjdk-8-jdk-headless'],
        }

        package { 'openjdk-8-jdk':
          ensure    => installed,
        }

        package { 'openjdk-8-jdk-headless':
          ensure => installed,
          before => Package['openjdk-8-jdk'],
        }

        apt::pin { 'openjdk-8-jdk':
          packages => ['openjdk-8-jdk',
                        'openjdk-8-jdk-headless',
                        "ca-certificates-java=${ca_certs_java_version}",
          ],
          release  => "${facts['os']['distro']['codename']}-backports",
          priority => '1000',
          before   => [Package['openjdk-8-jdk'],
                        Package['openjdk-8-jdk-headless'],
                        Package["ca-certificates-java=${ca_certs_java_version}"],
          ],
        }
      }
    }
    default: {
      notify { "profile::jenkins::usage::java cannot set up JDKs on ${facts['os']['family']}": }
    }
  }

  # jdk_switcher
  file { "${jenkins_home}/jdk_switcher.sh":
    ensure => file,
    source => 'puppet:///modules/profile/jenkins/jdk_switcher.sh',
    owner  => $jenkins_owner,
    group  => $jenkins_group,
    mode   => '0755',
  }
}
