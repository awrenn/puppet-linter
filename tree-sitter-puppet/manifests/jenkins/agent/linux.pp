# Class: profile::jenkins::agent::linux
# Install a PL approved Jenkins agent running on Linux.
#
# @param allow_dev_access set to true to allow developers access to the agent
#
class profile::jenkins::agent::linux (
  Boolean $allow_dev_access = true,
  ) {
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
  include profile::jenkins::params
  include profile::jenkins::agent::linux::jenkins_dir

  # Allow developers access to build agents
  if $allow_dev_access {
    include profile::dev::admin
  }

  # Bring variables in-scope to improve readability
  $master_url                = $profile::jenkins::agent::master_url
  $master_user               = $profile::jenkins::agent::master_user
  $master_pass               = unwrap(lookup('profile::jenkins::agent::sensitive_master_pass'))
  $executors                 = $profile::jenkins::agent::executors
  $labels                    = $profile::jenkins::agent::labels
  $agent_alias               = $profile::jenkins::agent::agent_alias
  $tmpclean_enabled          = $profile::jenkins::agent::tmpclean_enabled
  $workspace_cleanup_enabled = $profile::jenkins::agent::workspace_cleanup_enabled
  $process_cleanup_enabled   = $profile::jenkins::agent::process_cleanup_enabled
  $agent_home                = $profile::jenkins::params::agent_home
  $install_agent_java11      = $profile::jenkins::agent::install_agent_java11
  $agent_version             = $profile::jenkins::params::agent_version

  $jenkins_agent_agent_name = $agent_alias ? {
    'undef'    => undef,
    default    => $agent_alias
  }

  $jenkins_agent_ui_user = $master_user ? {
    ''      => undef,
    default => $master_user,
  }

  $jenkins_agent_ui_pass = $master_pass ? {
    ''      => undef,
    default => $master_pass,
  }

  # Realize the 'jenkins' user
  Account::User <| tag == 'jenkins' |>

  if $executors {
    $_executors = Integer($executors)
  } else {
    $_executors = executors
  }

  class { 'jenkins::slave':
    masterurl                => $master_url,
    executors                => $_executors,
    labels                   => $labels,
    slave_name               => $jenkins_agent_agent_name,
    ui_user                  => $jenkins_agent_ui_user,
    ui_pass                  => $jenkins_agent_ui_pass,
    version                  => $agent_version,
    slave_user               => $profile::jenkins::params::jenkins_owner,
    slave_home               => $profile::jenkins::params::agent_home,
    manage_slave_user        => false,
    require                  => Account::User[$profile::jenkins::params::jenkins_owner],
    install_java             => !$install_agent_java11,
    disable_ssl_verification => true,
  }

  if $install_agent_java11 {
    include profile::jenkins::usage::java11
  }

  # Manage some prerequisite packages that should be on all our Linux systems
  #   - Git is required for everything
  #   - Beaker requires libicu-dev
  #   - Nokogiri requires libxml2-dev and libxslt-dev
  #   - Hardware Infrastructure gem needs libvirt-dev and libsasl2-modules
  if $facts['os']['family'] == 'Debian' {
    include libxslt1
    include jq

    # Jenkins boxes with the 'vanagon' label are hosts that kick off vanagon
    # builds. Vanagon clones all of the needed projects and submodules on the
    # box that kicks off the builds. Wheezy comes with git 1.7.10, which seems
    # to have a bug where when updating submodules with `--work-tree` passed,
    # the update will fail if `--work-tree` already exists. So, if we have a
    # vanagon box running wheezy, let's pin git and git-core from backports so
    # we can have a newer git and not run into this bug.
    if $labels =~ /vanagon/ and "${facts['os']['distro']['codename']}" == 'wheezy' {
      apt::pin { 'git':
        packages => ['git', 'git-core'],
        release  => "${facts['os']['distro']['codename']}-backports",
        priority => '1000',
        require  => Class['apt::backports'],
        before   => [Package['git'], Package['git-core']],
      }

      ensure_packages(['git'], {'ensure' => 'installed'})
    }

    $needed_packages = [
      'build-essential',
      'expect',
      'gettext',
      'git-core',
      'gsfonts',
      'imagemagick',
      'libicu-dev',
      'libmagickwand-dev',
      'libsasl2-modules',
      'libvirt-dev',
      'libxml2-dev',
      'redis-tools',
      'xmlstarlet',
    ]

    ensure_packages($needed_packages, {'ensure' => 'installed'})
  } elsif $facts['os']['family'] == 'RedHat' {
    $needed_packages = [
      'git',
      'libicu-devel',
      'redis',
    ]

    ensure_packages($needed_packages, {'ensure' => 'installed'})
  }
}
