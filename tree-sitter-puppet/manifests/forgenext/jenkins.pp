# == Class: profile::forge::jenkins
#
# Profile for setting up the Jenkins-based Anubis module evaluation service,
# designed to be included in an existing server profile for now.

# much of the jenkins management code in this profile doesn't really work
# and only doesn't throw errors because it doesn't run when the node is already
# configured more or less correctly
#
# Manual setup steps needed with this profile:
# - copy /var/lib/jenkins/plugins and /var/lib/jenkins/jobs from a working anubis master
# - copy /var/lib/jenkins/config.xml from a working anubis (jenkins) master
class profile::forgenext::jenkins (
  $jenkins_home    = '/var/lib/jenkins',
  $jenkins_part    = false,
  $jenkins_version = 'present',
  $plugin_install  = false,
) {
  include git

  class {'::profile::forgenext::rbenv':
    ruby_versions => ['2.5.1', '2.4.4', '2.3.1', '2.1.9'],
  }

  class { 'jenkins':
    repo               => false,
    configure_firewall => false,
    version            => $jenkins_version,
    manage_user        => false,
    manage_group       => false,
    manage_datadirs    => false,
  }

  Alternatives['java'] -> Service['jenkins']

  class { '::profile::nginx::proxy_ssl':
    hostname         => $facts['networking']['fqdn'],
    proxy_port       => 8080,
    proxy_set_header => [
      'Host $host',
      'X-Real-IP $remote_addr',
      'X-Forwarded-For $proxy_add_x_forwarded_for',
      'X-Forwarded-Proto $scheme',
    ],
  }

  # Install JRE 1.8
  package { 'openjdk-8-jre-headless':
    ensure => present,
  }

  alternatives { 'java':
    path    => '/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java',
    require => Package['openjdk-8-jre-headless'],
  }

  # Realize the jenkins virtual user resource
  Account::User <| tag == 'jenkins' |>

  firewall { '100 allow inbound 80 and 443':
    dport  => ['80', '443'],
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '100 allow inbound 80 and 443 v6':
    dport    => ['80', '443'],
    proto    => 'tcp',
    action   => 'accept',
    provider => 'ip6tables',
  }

  firewall { '100 allow inbound jenkins agent':
    dport  => ['44897'],
    proto  => 'tcp',
    action => 'accept',
  }

  # Make sure the JenkinsLocationConfiguration.xml file exists at all, with
  # the right permissions, then update the jenkinsUrl line in the file.
  file { '/var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml':
    ensure => file,
    owner  => 'jenkins',
    group  => 'jenkins',
    mode   => '0644',
    before => File_line['/var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml'],
  }
  file_line { '/var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml':
    ensure  => present,
    path    => '/var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml',
    line    => "<jenkinsUrl>https://${facts['networking']['fqdn']}/</jenkinsUrl>",
    match   => '^\<jenkinsUrl\>\S*\<\/jenkinsUrl\>$',
    notify  => Service['jenkins'],
    require => File['/var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml'],
  }
}
