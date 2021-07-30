# Install chocolatey package manager and keep it updated
#
# NOTE: We set chocolatey to be the default package provider on Windows in site.pp
class profile::chocolatey {
  include chocolatey

  package { 'chocolatey':
    ensure   => latest,
  }

  chocolateysource { 'chocolatey':
    ensure   => present,
    location => 'https://chocolatey.org/api/v2/',
    priority => 0,
    require  => Package['chocolatey'],
  }

  chocolateysource { 'artifactory':
    ensure   => present,
    location => 'https://artifactory.delivery.puppetlabs.net/artifactory/api/nuget/nuget__local/',
    priority => 1,
    require  => Package['chocolatey'],
  }
}
