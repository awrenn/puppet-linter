# Class: profile::base::puppet
#
# Base class for managing the puppet agent from 2015.2.0 onwards.
#
# By default this persists the current environment into puppet.conf. To only run
# once in a given environment, use the persist_environment fact:
#
#   sudo FACTER_persist_environment=false puppet agent --test ...
#
# This is particularly useful in comparing code in different environments, since
# it suppresses the noise of writing the environment changes to puppet.conf.
#
# @param $ca_server [String[1]] The hostname to use to connect to the puppet CA in the future.
# @param $server [String[1]] The hostname to use to connect to puppet in the future.
# @param $confdir [String[1]] The value for confdir, where puppet.conf is located.
# @param $srv_domain [Optional[String[1]]] The domain to use for SRV discovery. `undef` to not use SRV records.
#
# @param $manage_package [Boolean] Whether to manage the package and repos or not. Installs the AIO agent.
# @param $package_version [Optional[String[1]]] If set, the proper version string to use for the puppet agent package.
# @param $package_source [Optional[String[1]]] The value to use for the `source` parameter on the `puppet_agent` class.
#
# @param $splay [Boolean] If true, use the puppet agent and the `splay` setting, else use a cron script.
# @param $cron_hour [Variant[Enum['*'], Integer[0,23], Array[Integer[0,23]]]] The hour setting for the agent cron job.
# @param $cron_minute [Variant[Integer[0,59], Array[Integer[0,59]]]] The minute setting for the agent cron job.
# @param $noop_server [Optional[String[1]]] If set, run a time-offset noop agent run against the specified server.
#
class profile::base::puppet (
  String[1] $ca_server = $profile::base::puppet::params::ca_server,
  String[1] $server = $profile::base::puppet::params::server,
  String[1] $confdir = $profile::base::puppet::params::confdir,

  Boolean $manage_package = $profile::base::puppet::params::manage_package,
  Boolean $manage_repo = $profile::base::puppet::params::manage_repo,
  Optional[String[1]] $package_version = $profile::base::puppet::params::package_version,
  Optional[String[1]] $package_source = undef,

  Boolean $splay = $profile::base::puppet::params::splay,
  Integer $run_interval = 30,
  Variant[Enum['*'], Integer[0,23], Array[Integer[0,23]]] $cron_hour = '*',
  Variant[Integer[0,59], Array[Integer[0,59]]] $cron_minute = [fqdn_rand($run_interval), fqdn_rand($run_interval) + $run_interval],
  Optional[String[1]] $noop_server = undef,

  String[5] $puppet_runner_version = '2.1.0',

) inherits profile::base::puppet::params {
  case $facts['persist_environment'] {
    undef, true, 'true': { $persist_environment = true }
    false, 'false':      { $persist_environment = false }
    default:             {
      fail("Invalid value for fact persist_environment: ${facts['persist_environment']}")
    }
  }

  # We don't need the autosign token now that the cert has been signed and
  # puppet is running. Ensure it's been deleted in cases it's a reusable one.
  file { "${confdir}/csr_attributes.yaml":
    ensure => absent,
  }

  if $manage_package {
    class { 'puppet_agent':
      package_version => $package_version,
      source          => $package_source,
      manage_repo     => $manage_repo,
    }
    contain puppet_agent

    $ini_require = { require => [Class['puppet_agent']] }
  } else {
    $ini_require = {}
  }

  #If this is an EC2 instance, we want to use the fqdn and not trusted.certname (e.g. i-00507983ac1290b35)
  if $facts['ec2_metadata'] {
    $_certname = $facts['networking']['fqdn']
  } else {
    $_certname = $trusted['certname']
  }

  if $persist_environment {
    $ini_settings = {
      'main' => {
        'certname' => $_certname,
        'server' => $server,
        'ca_server' => $ca_server,
        'http_read_timeout' => '15m',
        'usecacheonfailure' => 'false',
        'environment' => undef,
        'splay' => undef,
        'splaylimit' => undef,
        'use_srv_records' => undef,
        'srv_domain' => undef,
        'configtimeout' => undef,
        'archive_files' => undef,
        'archive_file_server' => undef,
        'vardir' => undef,
        'logdir' => undef,
        'rundir' => undef,
      },
      'agent' => {
        'environment' => $::environment,
        'splay' => "${splay}",
        'splaylimit' => $splay ? {
          true  => '25m',
          false => undef,
        },
        'use_srv_records' => undef,
        'srv_domain' => undef,
        'configtimeout' => undef,
        'archive_file_server' => undef,
        'vardir' => undef,
        'logdir' => undef,
        'rundir' => undef,
      },
    }

    $ini_settings.each |$section, $settings_hash| {
      $settings_hash.each |$setting_name, $value| {
        if $value {
          ini_setting { "pe-${section}-${setting_name}":
            ensure  => present,
            path    => "${confdir}/puppet.conf",
            section => $section,
            setting => $setting_name,
            value   => $value,
            *       => $ini_require,
          }
        } else {
          ini_setting { "pe-${section}-${setting_name}":
            ensure  => absent,
            path    => "${confdir}/puppet.conf",
            section => $section,
            setting => $setting_name,
            *       => $ini_require,
          }
        }
      }
    }
  }

  # Splaying is inconsistent, so we use cron where possible
  if $splay {
    service { 'puppet':
      ensure => running,
      enable => true,
    }
  } else {
    if $facts['kernel'] == 'SunOS' and $facts['os']['architecture'] != 'i86pc' {
      service { 'puppet':
        ensure => stopped,
        enable => false,
      }

      include puppetlabs::scripts

      class { 'profile::base::puppet::cron::sysenv':
        cron_hour   => $cron_hour,
        cron_minute => $cron_minute,
      }
    } else {
      class {'puppet_runner':
        version => $puppet_runner_version,
      }

      # clean up python version
      if $facts['kernel'] == 'windows' {
        scheduled_task { 'pe agent':
          ensure  => absent,
        }
      } else {
        file { '/opt/puppet-cron':
          ensure => absent,
          force  => true,
        }

        cron { 'pe agent':
          ensure => absent,
        }
      }
    }

    # perform noop agent runs against the puppet server used by the puppetserver team to test changes
    # the purpose of the plugin download is to restore facts, functions, etc from the normal server
    unless $facts['kernel'] == 'windows' {
      if $noop_server {
        cron { 'pe agent noop run':
          ensure      => present,
          command     => "puppet agent --no-daemonize --onetime --noop --server ${noop_server} > /dev/null 2>&1; puppet plugin download > /dev/null 2>&1",
          environment => $facts['os']['family'] ? {
            'Solaris' => undef,
            default   => 'PATH=/opt/puppetlabs/bin:/opt/puppet/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
          },
          minute      => Array.new($cron_minute, true).map |$time| { ($time + 10) % 60 },
          hour        => $cron_hour,
        }
      } else {
        cron { 'pe agent noop run':
          ensure      => absent,
        }
      }
    }
  }
}
