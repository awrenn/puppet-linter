class profile::forgenext::worker (
  $master_password
) {
  include git
  $master_user = 'jenkins' # this never got changed in hiera anyway
  $jenkins_master = sort(puppetdb_query("inventory {
    facts.classification.stage = '${facts['classification']['stage']}' and
    resources {
      type = 'Class' and
      title = 'Profile::Forgenext::Jenkins'
    }
  }").map |$value| { $value['facts']['networking']['fqdn'] })[0]

  class { '::jenkins::slave':
    masterurl                => $jenkins_master,
    ui_user                  => $master_user,
    ui_pass                  => $master_password,
    disable_ssl_verification => true,
    executors                => $facts['processors']['count'] * 8,
  }

  file {'/home/jenkins-slave/.ruby_version':
    ensure  => present,
    content => '2.2.5',
    owner   => 'jenkins-slave',
    group   => 'jenkins-slave',
  }

  group { 'forge-jenkins':
    ensure => present,
  }

  user { 'forge-jenkins':
    ensure     => present,
    shell      => '/bin/bash',
    gid        => 'forge-jenkins',
    groups     => 'forge-admins',
    password   => '*',
    system     => true,
    comment    => 'Forge Jenkins',
    home       => '/home/forge-jenkins',
    managehome => true,
    require    => Group['forge-jenkins'],
  }

  file { '/home/forge-jenkins/.ssh':
    ensure  => directory,
    owner   => 'forge-jenkins',
    group   => 'forge-jenkins',
    mode    => '0700',
    require => User['forge-jenkins'],
  }

  Ssh::Authorized_key <| tag == 'forgeapi-keys' |> {
    user => 'forge-jenkins',
  }

  package { 'ruby-dev':
    ensure => 'present',
  }

}
