# Internal Ops CI - jenkins.ops.puppetlabs.net
class profile::ci::ops (
  String[1] $hostname        = $facts['networking']['fqdn'],
  String[1] $rootpw          = undef,
  String[1] $rootdn          = 'cn=root,dc=puppetlabs,dc=com',
  String[1] $ldapbase        = 'dc=puppetlabs,dc=com',
  String[1] $jenkins_version = 'present',
  Array[String[1]] $deb_packages = [],
) {
  class { '::jenkins':
    configure_firewall => false,
    version            => $jenkins_version,
    manage_user        => false,
    manage_group       => false,
    manage_datadirs    => false,
  }

  include profile::python
  include profile::python::plops

  python::pip { 'click':
    ensure => present,
  }

  # Fabric 2 does not work
  python::pip { 'fabric':
    ensure => '1.14.0',
  }

  $common_nginx_params = {
    hostname         => $hostname,
    proxy_port       => 8080,
    proxy_set_header => [
      'Host $host',
      'X-Real-IP $remote_addr',
      'X-Forwarded-For $proxy_add_x_forwarded_for',
    ],
  }

  class { '::profile::nginx::proxy_ssl':
    * => $common_nginx_params,
  }

  $tool_path = '/opt/tools'

  vcsrepo { $tool_path:
    ensure   => latest,
    provider => git,
    source   => 'git@github.com:puppetlabs/puppetlabs-sysadmin-tools.git',
    revision => 'master',
    user     => 'jenkins',
    owner    => 'jenkins',
    identity => '/var/lib/jenkins/.ssh/id_rsa',
  }

  python::virtualenv { $tool_path:
    owner => 'jenkins',
    group => 'jenkins',
  }

  # Needed for profile::jenkins::usage::nodejs
  file { '/var/lib/jenkins/.bashrc':
    ensure => file,
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  file { "${tool_path}/ldapdeploy/etc/config.yaml":
    ensure  => file,
    owner   => 'jenkins',
    group   => 'jenkins',
    content => template('profile/ci/ldapdeploy.config.yaml.erb'),
    require => Vcsrepo[$tool_path],
  }

  package { 'colorize':
    ensure   => installed,
    provider => 'gem',
  }

  package { 'awscli':
    ensure   => installed,
    provider => 'pip',
  }
}
