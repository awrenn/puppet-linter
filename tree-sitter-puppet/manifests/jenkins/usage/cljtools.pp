# Class: profile::jenkins::usage::cljtools
#
class profile::jenkins::usage::cljtools {
  profile_metadata::service { $title:
    human_name => 'Clojure build tools for Jenkins',
    team       => 'dio',
    doc_urls   => [
      'https://confluence.puppetlabs.com/display/SRE/Jenkins+Instances',
      'https://plugins.jenkins.io/swarm',
    ],
  }

  $lein_ver = lookup(
    'profile::jenkins::usage::cljtools::lein_version',
    { 'default_value' => '2.9.1' }
  )

  include profile::jenkins::params

  $lein_baseurl  = 'https://raw.githubusercontent.com/technomancy/leiningen'
  $jenkins_owner = $::profile::jenkins::params::jenkins_owner
  $agent_home    = $::profile::jenkins::params::agent_home

  $jenkins_username = lookup('profile::jenkins::agent::master_user')
  $jenkins_password = unwrap(lookup('profile::jenkins::agent::sensitive_master_pass'))

  Exec { path => '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin' }


  # Leiningen, as specified by $lein_ver
  # Maintain a versioned file and a symlink at '/usr/local/bin/lein'
  exec { "download-lein-${lein_ver}":
    command => "wget -O lein-${lein_ver} ${lein_baseurl}/${lein_ver}/bin/lein",
    cwd     => '/usr/local/bin',
    creates => "/usr/local/bin/lein-${lein_ver}",
  }
  file { "/usr/local/bin/lein-${lein_ver}":
    ensure  => file,
    mode    => '0755',
    require => Exec["download-lein-${lein_ver}"],
  }
  file { '/usr/local/bin/lein':
    ensure  => link,
    target  => "/usr/local/bin/lein-${lein_ver}",
    require => File["/usr/local/bin/lein-${lein_ver}"],
  }
  file { "${agent_home}/.lein":
    ensure => directory,
    owner  => $::profile::jenkins::params::jenkins_owner,
    group  => $::profile::jenkins::params::jenkins_group,
  }
  file { "${agent_home}/.lein/profiles.clj":
    ensure  => file,
    owner   => $::profile::jenkins::params::jenkins_owner,
    group   => $::profile::jenkins::params::jenkins_group,
    mode    => '0640',
    content => template('profile/jenkins/agent/cljtools/profiles.clj.erb'),
  }

  # Lein first-run must be executed as the 'jenkins' user.
  # The setup script will place files in '~/.lein'.
  exec { 'setup-lein':
    command   => "env HOME=${agent_home} lein",
    user      => $jenkins_owner,
    cwd       => $agent_home,
    creates   => "${agent_home}/.lein",
    subscribe => File['/usr/local/bin/lein'],
    require   => File['/usr/local/bin/lein'],
  }


  # Ensure there are some older versions of Lein available

  # Lein 2.7.1 is the oldest version of lein that supports clj-parent
  exec { 'download-lein-2.7.1':
    command => "wget --no-check-certificate -O lein-2.7.1 ${lein_baseurl}/2.7.1/bin/lein",
    cwd     => '/usr/local/bin',
    creates => '/usr/local/bin/lein-2.7.1',
  }
  file { '/usr/local/bin/lein-2.7.1':
    ensure  => file,
    mode    => '0755',
    require => Exec['download-lein-2.7.1'],
  }
}

