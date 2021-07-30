# A base profile for redis
class profile::redis (
  $ensure = present,
  String $bind = '0.0.0.0',
  String $port = '6379',
  Optional[String] $config_group = undef,
  Optional[String] $slaveof = undef,
  Optional[String] $extra_config_file = undef,
  Optional[Array] $extra_config_options = undef,
  Optional[String] $requirepass = undef,
  Optional[String] $masterauth = undef,
) {

  if $extra_config_file {
    $extra_config = "${redis::params::config_dir}/${extra_config_file}"
    if $extra_config_options {
      file { $extra_config:
        ensure  => present,
        content => join($extra_config_options, "\n"),
        mode    => '0444',
      }
    } else {
      file { $extra_config:
        ensure => absent,
      }
    }
  }

  class { 'redis':
    package_ensure    => $ensure,
    bind              => $bind,
    slaveof           => $slaveof,
    port              => $port,
    extra_config_file => $extra_config,
    config_group      => $config_group,
    requirepass       => $requirepass,
    masterauth        => $masterauth,
  }

  if $profile::server::params::fw      { include profile::redis::firewall }
  if $profile::server::params::monitoring { include profile::redis::monitor }
}
