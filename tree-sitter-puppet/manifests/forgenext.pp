# == Class: profile::forgenext
#
# Default profile used by all Forge.
#
# === Authors
#
#  Puppet Ops <opsteam@puppetlabs.com>
#
# === Copyright
#
# Copyright 2014 Puppet Labs, unless otherwise noted.
#
class profile::forgenext {
  include virtual::users
  include profile::aws::cli
  include profile::gcloudsdk

  Account::User <| groups == 'forge-admins' or group == 'forge-admins' or groups == 'forge-users' |>
  Group         <| title  == 'forge-admins' or title == 'forge-users' |>

  # Allow SSH: forge-admins group
  ssh::allowgroup { ['forge-admins', 'forge-users']: }

  # Allow full sudo: forge-admins group
  sudo::allowgroup { 'forge-admins': }

  package { 'bundler':
    ensure   => '1.17.3',
    provider => 'gem',
  }

  if $facts['os']['name'] == 'Debian' and $facts['os']['release']['major'] == '8' {
    include apt::backports

    apt::pin { 'rsyslog-backports':
      packages => [
        'rsyslog',
        'rsyslog-gnutls',
        'rsyslog-relp',
        'librelp0',
      ],
      release  => "${facts['os']['distro']['codename']}-backports",
      priority => '1000',
      require  => Class['apt::backports'],
    }

    # Ensure backports are configured before installing packages.
    Apt::Pin <| title == 'rsyslog-backports' |> -> Package <| |>
  }

  # Remove unnecessary drupal.log files from Forge servers. This block
  # can be removed in a subsequent PR, since drupal.log should no longer
  # be added by default.
  file { '/var/log/drupal.log':
    ensure => absent,
  }

  if $facts['classification']['stage'] == 'pentest' {
    # Pentest env can't connect to consul infra, so suppress error messages that fill up logs
    $consul_log_conf = @(EOT)
      :programname, startswith, "consul" {
        stop
      }
      | EOT

    file { '/etc/rsyslog.d/100-consul.conf':
      ensure  => present,
      content => $consul_log_conf,
      notify  => Service['rsyslog'],
    }

    # Pentest env can't connect to graphite infra, so suppress error messages that fill up logs
    # I know matching 'python' is a little broad, but this is a throwaway env
    $diamond_log_conf = @(EOT)
      :programname, startswith, "python" {
        stop
      }
      | EOT

    file { '/etc/rsyslog.d/100-diamond.conf':
      ensure  => present,
      content => $diamond_log_conf,
      notify  => Service['rsyslog'],
    }
  }
}
