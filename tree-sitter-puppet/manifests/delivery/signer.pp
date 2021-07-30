# Class: profile::delivery::signer
#
class profile::delivery::signer {
  include profile::jenkins::params
  include profile::server::params
  include profile::aws::cli
  include s3cmd

  if $::profile::server::params::monitoring {
    include profile::delivery::signer::monitor
  }

  $jenkins_home  = $::profile::jenkins::params::agent_home
  $jenkins_owner = $::profile::jenkins::params::jenkins_owner
  $jenkins_group = $::profile::jenkins::params::jenkins_group

  file_line { 'signing_bashrc_01':
    path => "${jenkins_home}/.bashrc",
    line => 'export RPM_GPG_AGENT=true',
  }

  file_line { 'signing_bashrc_02':
    path    => "${jenkins_home}/.bashrc",
    line    => "export RPM=${jenkins_home}/bin/rpmwrapper",
    after   => 'export RPM_GPG_AGENT=true',
    require => [
      File["${jenkins_home}/bin"],
      File["${jenkins_home}/bin/rpmwrapper"],
    ],
  }

  file_line { 'signing_bashrc_03':
    path  => "${jenkins_home}/.bashrc",
    line  => "[ -e ${jenkins_home}/.gpg-agent-info ] && . ${jenkins_home}/.gpg-agent-info",
    after => "export RPM=${jenkins_home}/bin/rpmwrapper",
  }

  file_line { 'signing_bashrc_04':
    path  => "${jenkins_home}/.bashrc",
    line  => 'export GPG_AGENT_INFO',
    after => "\\[ -e ${jenkins_home}/.gpg-agent-info \\] && . ${jenkins_home}/.gpg-agent-info",
  }

  # Prevents secrets from showing up in jenkins' history.
  file_line { 'HISTIGNORE gpg-preset-passphrase':
    path => "${jenkins_home}/.bashrc",
    line => 'export HISTIGNORE=$HISTIGNORE:*gpg-preset-passphrase*',
  }

  file_line { 'allow_preset_passphrase':
    path    => "${jenkins_home}/.gnupg/gpg-agent.conf",
    line    => 'allow-preset-passphrase',
    require => File["${jenkins_home}/.gnupg"],
  }

  file_line { 'TTL for passphrase caching 1':
    path    => "${jenkins_home}/.gnupg/gpg-agent.conf",
    line    => 'default-cache-ttl 34560000',
    require => File["${jenkins_home}/.gnupg"],
  }

  file_line { 'TTL for passphrase caching 2':
    path    => "${jenkins_home}/.gnupg/gpg-agent.conf",
    line    => 'max-cache-ttl 34560000',
    require => File["${jenkins_home}/.gnupg"],
  }

  file { "${jenkins_home}/.gnupg":
    ensure => directory,
    mode   => '0700',
  }

  file { "${jenkins_home}/bin":
    ensure  => directory,
    owner   => $jenkins_owner,
    group   => $jenkins_group,
    require => User[$jenkins_owner],
  }

  file { "${jenkins_home}/bin/rpmwrapper":
    ensure  => file,
    owner   => $jenkins_owner,
    group   => $jenkins_group,
    source  => 'puppet:///modules/profile/delivery/rpmwrapper',
    mode    => '0755',
    require => File["${jenkins_home}/.bashrc"],
  }

  # s3cmd configuration
  file { "${jenkins_home}/.s3cfg":
    ensure => file,
    owner  => $jenkins_owner,
    group  => $jenkins_group,
    mode   => '0600',
    source => 'puppet:///modules/profile/delivery/s3cfg',
  }

  file_line { 's3 access key in .s3cfg':
    path    => "${jenkins_home}/.s3cfg",
    line    => "access_key = ${lookup('profile::delivery::signer::s3_access_key')}",
    require => File["${jenkins_home}/.s3cfg"],
  }

  file_line { 's3 secret key in .s3cfg':
    path    => "${jenkins_home}/.s3cfg",
    line    => "secret_key = ${unwrap(lookup('profile::delivery::signer::sensitive_s3_secret_key'))}",
    require => File["${jenkins_home}/.s3cfg"],
  }
}
