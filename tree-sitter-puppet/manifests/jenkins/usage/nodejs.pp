# Class: profile::jenkins::usage::nodejs
#
class profile::jenkins::usage::nodejs {
  case $facts['os']['family'] {
    'debian': {
      profile_metadata::service { $title:
        human_name => 'Nodejs build tools for Jenkins',
        team       => 'dio',
        doc_urls   => [
          'https://confluence.puppetlabs.com/display/SRE/Jenkins+Instances',
          'https://plugins.jenkins.io/swarm',
        ],
      }

      include profile::jenkins::params
      include profile::apt
      include profile::nodejs
      include jq

      $agent_home  = $::profile::jenkins::params::agent_home
      $agent_user  = $::profile::jenkins::params::jenkins_owner

      package { ['grunt-cli', 'ember-cli', 'bower']:
        ensure   => present,
        provider => 'npm',
        require  => Class['::profile::nodejs'],
      }

      package { 'phantomjs-prebuilt':
        ensure   => '2.1.7',
        provider => 'npm',
        require  => Class['::profile::nodejs'],
      }

      vcsrepo { "${agent_home}/.nvm":
        ensure   => present,
        provider => git,
        owner    => $agent_user,
        user     => $agent_user,
        source   => 'https://github.com/creationix/nvm.git',
        revision => 'ec33e8b720b19a77230e4718857164532dcf005d',
      }

      file_line { 'jenkins agent user bashrc source nvm':
        ensure => present,
        line   => "source ${agent_home}/.nvm/nvm.sh",
        path   => "${agent_home}/.bashrc",
      }
    }
    default: {
      notify { "profile::jenkins::usage::nodejs is not supported on OS family '${facts['os']['family']}'": }
    }
  }
}
