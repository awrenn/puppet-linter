# Class: profile::puppetserver::perf::driver::base
#
# Base class for configuring Puppet Server perf testing driver node.
# Most of the logic for that lives in the puppetlabs-puppetserver_perf_driver
# module; this class just contains some things that are specific to the
# SysOps PE environment.
class profile::puppetserver::perf::driver::base {
  include profile::jenkins::usage::ruby
  include git

  Account::User <| groups == 'puppet-server' |>
  ssh::allowgroup  { 'puppet-server': }
  sudo::allowgroup { 'puppet-server': }

  # We need the Jenkins user's home directory to be under `/home` because
  # the disk partitions are set up such that `/` does not have enough
  # space to store our job history.
  $jenkins_home_dir = '/home/jenkins'
  Account::User <| groups == 'jenkins' |> { home => $jenkins_home_dir }

  # Jenkins SSH keys
  # NOTE: this stuff is copied from profile::jenkins::master; it
  #  would be nice to refactor it into a class like
  #  jenkins::master::ssh_keys that could be included for our use case

  include profile::jenkins::params

  $jenkins_owner          = $::profile::jenkins::params::jenkins_owner
  $jenkins_group          = $::profile::jenkins::params::jenkins_group
  $master_config_dir      = $jenkins_home_dir

  file { "${master_config_dir}/.ssh":
    ensure => directory,
    owner  => $jenkins_owner,
    group  => $jenkins_group,
    mode   => '0700',
  }

  file { "${master_config_dir}/.ssh/id_rsa":
    ensure  => file,
    owner   => $jenkins_owner,
    group   => $jenkins_group,
    mode    => '0600',
    content => "${lookup('profile::jenkins::agent::id_rsa_jenkins')}\n",
  }

  file { "${master_config_dir}/.ssh/id_rsa.pub":
    ensure  => file,
    owner   => $jenkins_owner,
    group   => $jenkins_group,
    mode    => '0640',
    content => "${lookup('profile::jenkins::agent::id_rsa_jenkins_pub')}\n",
  }

  file { '/var/lib/jenkins':
    ensure => link,
    target => $jenkins_home_dir,
    owner  => $jenkins_owner,
    group  => $jenkins_group,
    mode   => '0700',
  }
}
