# Class: profile::jenkins::agent::windows
# All the power of Jenkins, at enterprise scale.
#
class profile::jenkins::agent::windows {
  include profile::jenkins::agent
  include profile::jenkins::params
  include profile::jenkins::agent::windows::service

  # Bring variables in-scope to improve readability
  $jenkins_owner = $::profile::jenkins::params::jenkins_owner
  $jenkins_group = $::profile::jenkins::params::jenkins_group
  $agent_home    = $::profile::jenkins::params::agent_home

  # Some sane resource defaults
  File    { source_permissions => 'ignore'     }
  Package { provider           => 'chocolatey' }

  package { ['javaruntime', 'git']:
    ensure => installed,
  }

  windows_env { 'git-on-path':
    ensure    => present,
    variable  => 'PATH',
    value     => [
      'C:\Program Files\Git\cmd',
      'C:\Program Files (x86)\Git\cmd',
    ],
    mergemode => 'prepend',
    require   => Package['git'],
  }

  user { $jenkins_owner:
    ensure     => present,
    home       => $agent_home,
    password   => unwrap(lookup('profile::jenkins::agent::sensitive_master_pass')),
    managehome => true,
    groups     => ['Administrators'],
    comment    => 'Jenkins User',
  }

  file { $agent_home:
    ensure  => directory,
    owner   => 'S-1-5-32-544', # BUILTIN\Administrators
    group   => 'S-1-0-0',      # NULL, managed by acl resource below
    require => User[$jenkins_owner],
  }

  acl { $agent_home:
    permissions                => [
      { identity => 'S-1-5-32-544',  rights => [ 'full' ] }, # BUILTIN\Administrators
      { identity => 'S-1-5-18',      rights => [ 'full' ] }, # NT AUTHORITY\SYSTEM
      { identity => 'Administrator', rights => [ 'full' ] },
      { identity => $jenkins_owner,  rights => [ 'full' ] },
    ],
    inherit_parent_permissions => false,
    require                    => File[$agent_home],
  }

  # Deploy Jenkins and vmpooler SSH keys and configs
  file { "${agent_home}/.ssh":
    ensure  => directory,
    mode    => '0770',
    owner   => $jenkins_owner,
    group   => $jenkins_group,
    require => User[$jenkins_owner],
  }

  file { "${agent_home}/.ssh/id_rsa":
    ensure  => file,
    mode    => '0660',
    owner   => $jenkins_owner,
    group   => $jenkins_group,
    content => "${lookup('profile::jenkins::agent::id_rsa_jenkins')}\n",
  }

  file { "${agent_home}/.ssh/id_rsa.pub":
    ensure  => file,
    mode    => '0660',
    owner   => $jenkins_owner,
    group   => $jenkins_group,
    content => "${lookup('profile::jenkins::agent::id_rsa_jenkins')}\n",
  }

  file { "${agent_home}/.ssh/config":
    ensure => file,
    mode   => '0660',
    owner  => $jenkins_owner,
    group  => $jenkins_group,
    source => 'puppet:///modules/profile/jenkins/agent/ssh_config',
  }

  file { "${agent_home}/.gitconfig":
    ensure  => file,
    mode    => '0660',
    owner   => $jenkins_owner,
    group   => $jenkins_group,
    source  => 'puppet:///modules/profile/jenkins/agent/gitconfig',
    require => User[$jenkins_owner],
  }

  # Deploy insecure vmpooler SSH keys
  file { "${agent_home}/.ssh/id_rsa-acceptance":
    ensure  => file,
    owner   => $jenkins_owner,
    group   => $jenkins_group,
    mode    => '0660',
    content => "${lookup('profile::jenkins::agent::id_rsa_acceptance')}\n",
  }

  file { "${agent_home}/.ssh/id_rsa-acceptance.pub":
    ensure  => file,
    owner   => $jenkins_owner,
    group   => $jenkins_group,
    mode    => '0660',
    content => "${lookup('profile::jenkins::agent::id_rsa_acceptance_pub')}\n",
  }

  # Set up a more relaxed local security policy, since the Jenkins user's
  # password doesn't meet the Windows complexity requirements, but it meets
  # Puppet Labs' LDAP requirements.
  Local_security_policy { ensure => present }

  local_security_policy { 'Enforce password history':
    policy_value => '0',
    notify       => Reboot['reboot-to-apply-local-security-policy'],
  }
  local_security_policy { 'Minimum password length':
    policy_value => '0',
    notify       => Reboot['reboot-to-apply-local-security-policy'],
  }
  local_security_policy { 'Password must meet complexity requirements':
    policy_value => '0',
    notify       => Reboot['reboot-to-apply-local-security-policy'],
  }
  local_security_policy { 'Maximum password age':
    policy_value => '999',
    notify       => Reboot['reboot-to-apply-local-security-policy'],
  }
  local_security_policy { 'Accounts: Limit local account use of blank passwords to console logon only':
    policy_value => '0',
    notify       => Reboot['reboot-to-apply-local-security-policy'],
  }

  reboot { 'reboot-to-apply-local-security-policy':
    message => 'Host rebooted by Puppet to apply Local Security Policy',
    before  => User[$jenkins_owner],
  }
}
