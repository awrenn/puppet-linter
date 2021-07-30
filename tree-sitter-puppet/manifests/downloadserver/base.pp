# This profile includes some base classes and configuration options that are required by the web and repo profiles.
class profile::downloadserver::base {

  include profile::server
  include profile::ssl::wildcard
  include profile::logging::logstashforwarder
  include profile::server::params

  if $profile::server::params::monitoring {
    include profile::downloadserver::monitor
  }

  if $profile::server::params::firewall {
    include profile::fw::https
  }

  ssh::allowgroup  { 'enterprise': }
  ssh::allowgroup  { 'httpdlogsync': }
  ssh::allowgroup  { 'jenkins': }

  Account::User <| title == 'deploy' |>
  Account::User <| tag == 'jenkins' |>
  Account::User <| tag == 'httpdlogsync' |>
  Package <| title == 'mlocate' |>
  Ssh_authorized_key <| tag == 'jenkins' |>

  file { '/opt/repository':
    ensure => directory,
    owner  => 'root',
    group  => 'release',
    mode   => '02775',
  }

  file {'/var/log/apache2':
    ensure => directory,
    mode   => '0755',
  }

  file {'/var/log/apache2/rotated':
    ensure  => directory,
    mode    => '0755',
    owner   => 'httpdlogsync',
    group   => 'httpdlogsync',
    require => File['/var/log/apache2'],
  }

  file {'/etc/logrotate.d/apache2':
    ensure => file,
    group  => 'root',
    owner  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/profile/downloadserver/logrotate_apache2',
  }

  ::logstashforwarder::file { 'pe_downloads':
    paths  =>  [ '/var/log/apache2/pm.*json_access.log' ],
    fields =>  { 'type'  => 'pe_downloads' },
  }

  cron { 'logstash-fowarder':
    command => '/etc/init.d/logstash-forwarder restart',
    user    => 'root',
    hour    => 18,
    minute  => 0,
  }
}
