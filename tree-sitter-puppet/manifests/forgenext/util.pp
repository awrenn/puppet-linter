# == Class: profile::forgenext::util
#
# Gerenal profile class for creating Forge Util Service Instances.
#
# === Authors
#
#  Puppet Ops <opsteam@puppetlabs.com>
#
# === Copyright
#
# Copyright 2014 Puppet Labs, unless otherwise noted.
#
class profile::forgenext::util (
  $db_user       = undef,
  $db_password   = undef,
  $db_host       = undef,
  $db_name       = undef,
  $bcrypt_secret = undef,
  $user          = 'forge-api',
  $group         = 'forge-api',
  $source        = 'git@github.com:puppetlabs/puppet-forge-api',
  $app_root      = '/opt/forge-api',
  $rack_env      = 'production',
  $user_home     = '/var/lib/forge-api',
  $manageuser    = true,
  $files         = false,
  $backend       = 'S3',
  $amazon_secret = undef,
  $amazon_id     = undef,
  $amazon_bucket = undef,
  $amazon_region = 'us-west-2',
  $elasticsearch_url = undef,
) {
  include profile::server
  include profile::forgenext::apt_postgres

  # set motd messages
  meta_motd::register { 'Forge Util Profile': }
  meta_motd::register { 'Forge API Partial Profile': }

  # Add statsd Service
  # Note that ::profile::statsd declares ::profile::nodejs, which is also a
  # requirement of the asset generation pipeline, but we don't include it here
  # to avoid a duplicate class declaration.
  include profile::statsd

  apt::pin { 'postgresql-client-libs':
    ensure   => present,
    packages => ['libpq5', 'libpq-dev', 'postgresql-client'],
    version  => '11*',
    priority => '999',
    require  => Class['profile::forgenext::apt_postgres'],
  }

  ensure_packages(
    [
      'libxslt1-dev',
      'libxml2-dev',
      'libxml2',
      'libxslt1.1',
      'jq',
      'libjq-dev',
      'libpq5',
      'libpq-dev',
    ],
    {
      'ensure'  => 'latest',
      'require' => Apt::Pin['postgresql-client-libs'],
    }
  )


  include puppetlabs::ssl
  include git

  if $manageuser {
    group { $group:
      ensure => present,
      gid    => '28952',
    }

    user { $user:
      ensure     => present,
      shell      => '/bin/bash',
      gid        => $group,
      groups     => 'forge-admins',
      password   => '*',
      system     => true,
      comment    => 'Puppet Labs API',
      home       => $user_home,
      managehome => true,
      require    => Group[$group],
      before     => File[$app_root],
    }
  }

  file { "${user_home}/.ssh":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0700',
    require => User[$user],
  }

  file { "${user_home}/.bash_aliases":
    ensure  => 'present',
    owner   => $user,
    group   => $group,
    mode    => '0700',
    content => template('profile/forge/bash_aliases.erb'),
    require => User[$user],
  }

  file {"${user_home}/.ssh/id_rsa":
    ensure  => 'present',
    source  => 'puppet:///modules/profile/forge/id_rsa_forge',
    owner   => $user,
    group   => $group,
    mode    => '0600',
    require => File["${user_home}/.ssh"],
  }

  Ssh::Authorized_key <| tag == 'forgeapi-keys' |> {
    user => $user,
  }

  file { $app_root:
    ensure => directory,
    owner  => $user,
    group  => $group,
  }

  file { [ "${app_root}/config", "${app_root}/log", "${app_root}/assets" ]:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    require => File[$app_root],
  }

  file { "${app_root}/config/settings.yml":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0640',
    content => template('profile/forge/api/settings.yml.erb'),
  }

  # Rotation job, so production.log doesn't get out of control!
  logrotate::job { 'util_forge-api':
    log        => "${app_root}/log/*.log",
    options    => [
      'rotate 7',
      'daily',
      'compress',
      'compresscmd /usr/bin/xz',
      'uncompresscmd /usr/bin/unxz',
      'compressext .xz',
      'notifempty',
      'sharedscripts',
      "create ${user} ${group}",
    ],
    postrotate => [
      "/bin/chown -R ${user}:${group} ${app_root}/log",
    ],
  }

  case $facts['classification']['stage'] {
    'prod': { $long_stage = 'production' }
    'stage': { $long_stage = 'staging' }
  }

  $cron_mailto = $facts['classification']['stage'] ? {
    'prod'  => 'MAILTO="forge-alerts@puppetlabs.com"',
    default => 'MAILTO=""',
  }

  $dlcount_cron_hour = $facts['classification']['stage'] ? {
    'prod'  => '*/4',
    default => 1,
  }

  file { "${user_home}/storage_validate.sh":
    ensure  => 'absent',
    require => User[$user],
  }

  file { "${user_home}/download_counts.sh":
    ensure  => 'absent',
    require => User[$user],
  }

  cron { 'storage_validate':
    ensure      => 'absent',
    command     => "${user_home}/storage_validate.sh",
    user        => $user,
    minute      => 30,
    hour        => 1,
    environment => "${cron_mailto}",
    require     => File["${user_home}/storage_validate.sh"],
  }

  cron { 'download_counts':
    ensure      => 'absent',
    command     => "${user_home}/download_counts.sh",
    user        => $user,
    minute      => 15,
    hour        => $dlcount_cron_hour,
    environment => "${cron_mailto}",
    require     => File["${user_home}/download_counts.sh"],
  }

  # Monitoring
  #if $::profile::server::monitoring {
    # not implemented in forgenext yet
    # include profile::forgenext::util::monitor
  #}
}
