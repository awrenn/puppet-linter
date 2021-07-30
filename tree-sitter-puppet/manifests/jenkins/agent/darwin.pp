# Class: profile::jenkins::agent::darwin
#
class profile::jenkins::agent::darwin {
  profile_metadata::service { $title:
    human_name        => "Jenkins agent service (${facts['kernel'].capitalize})",
    team              => 'dio',
    end_users         => ['infrastructure-users@puppetlabs.com'],
    escalation_period => 'pdx-workhours',
    downtime_impact   => @("END"),
      Jobs running on label "${labels}" will queue infinitely if all the Jenkins
      agents are down for those labels. We normally have 2 agents for redundancy.
      | END
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/Jenkins+Instances',
      'https://plugins.jenkins.io/swarm',
    ],
  }

  include profile::jenkins::agent
  include profile::jenkins::agent::fog
  include profile::jenkins::params
  include profile::jenkins::agent::darwin::service
  # Allow developers access to build agents
  include profile::dev::admin

  # Bring variables in-scope to improve readability
  $jenkins_owner = $::profile::jenkins::params::jenkins_owner
  $jenkins_group = $::profile::jenkins::params::jenkins_group
  $agent_home    = $::profile::jenkins::params::agent_home

  # Realize the 'jenkins' user
  Account::User <| tag == 'jenkins' |>

  file { "${agent_home}/.bashrc":
    ensure  => file,
    mode    => '0755',
    owner   => $::profile::jenkins::params::jenkins_owner,
    group   => $::profile::jenkins::params::jenkins_group,
    require => Account::User[$::profile::jenkins::params::jenkins_owner],
  }

  file { "${agent_home}/.ssh":
    ensure  => directory,
    mode    => '0700',
    owner   => $::profile::jenkins::params::jenkins_owner,
    group   => $::profile::jenkins::params::jenkins_group,
    require => Account::User[$::profile::jenkins::params::jenkins_owner],
  }

  # Deploy Jenkins SSH keys
  file { "${agent_home}/.ssh/id_rsa":
    ensure  => file,
    mode    => '0600',
    owner   => $::profile::jenkins::params::jenkins_owner,
    group   => $::profile::jenkins::params::jenkins_group,
    content => lookup('profile::jenkins::agent::id_rsa_jenkins'),
    require => Account::User[$::profile::jenkins::params::jenkins_owner],
  }

  file { "${agent_home}/.ssh/id_rsa.pub":
    ensure  => file,
    mode    => '0640',
    owner   => $::profile::jenkins::params::jenkins_owner,
    group   => $::profile::jenkins::params::jenkins_group,
    content => lookup('profile::jenkins::agent::id_rsa_jenkins_pub'),
    require => Account::User[$::profile::jenkins::params::jenkins_owner],
  }

  file { "${agent_home}/.ssh/config":
    ensure  => file,
    mode    => '0640',
    owner   => $::profile::jenkins::params::jenkins_owner,
    group   => $::profile::jenkins::params::jenkins_group,
    source  => 'puppet:///modules/profile/jenkins/agent/ssh_config',
    require => Account::User[$::profile::jenkins::params::jenkins_owner],
  }

  file { "${agent_home}/.gitconfig":
    ensure  => file,
    mode    => '0640',
    owner   => $::profile::jenkins::params::jenkins_owner,
    group   => $::profile::jenkins::params::jenkins_group,
    source  => 'puppet:///modules/profile/jenkins/agent/gitconfig',
    require => Account::User[$::profile::jenkins::params::jenkins_owner],
  }

  # Deploy SSH key for connecting to Google Compute instances
  file { "${agent_home}/.ssh/google_compute":
    ensure  => file,
    owner   => $::profile::jenkins::params::jenkins_owner,
    group   => $::profile::jenkins::params::jenkins_group,
    mode    => '0600',
    content => "${lookup('profile::jenkins::agent::google_compute')}\n",
    require => Account::User[$::profile::jenkins::params::jenkins_owner],
  }

  # Deploy SSH key for connecting to AWS EC2 instances
  file { "${agent_home}/.ssh/abs-aws-ec2.rsa":
    ensure  => file,
    owner   => $::profile::jenkins::params::jenkins_owner,
    group   => $::profile::jenkins::params::jenkins_group,
    mode    => '0600',
    content => "${lookup('profile::jenkins::agent::abs_aws_ec2_key')}\n",
    require => Account::User[$::profile::jenkins::params::jenkins_owner],
  }

  # Deploy insecure vmpooler SSH keys
  file { "${agent_home}/.ssh/id_rsa-acceptance":
    ensure  => file,
    owner   => $::profile::jenkins::params::jenkins_owner,
    group   => $::profile::jenkins::params::jenkins_group,
    mode    => '0600',
    content => "${lookup('profile::jenkins::agent::id_rsa_acceptance')}\n",
    require => Account::User[$::profile::jenkins::params::jenkins_owner],
  }

  file { "${agent_home}/.ssh/id_rsa-acceptance.pub":
    ensure  => file,
    owner   => $::profile::jenkins::params::jenkins_owner,
    group   => $::profile::jenkins::params::jenkins_group,
    mode    => '0640',
    content => "${lookup('profile::jenkins::agent::id_rsa_acceptance_pub')}\n",
    require => Account::User[$::profile::jenkins::params::jenkins_owner],
  }
}
