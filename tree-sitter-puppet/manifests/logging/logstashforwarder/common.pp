##
#
class profile::logging::logstashforwarder::common {
  include ssl

  $package_name = 'logstash-forwarder'
  $configdir = "/etc/${package_name}"
  $installpath = "/opt/${package_name}"
  $spoolsize = 1024
  $logstash_host = hiera('logstash::server')

  # Keeping the Linux kernel confinement here incase we ever do kfreebsd
  if $facts['kernel'] == 'Linux' {
    if $facts['os']['family'] == 'Redhat' {
      $package_url = 'puppet:///modules/profile/logging/logstashforwarder/common/logstash-forwarder-0.4.0-1.x86_64.rpm'
    } else {
      $package_url = undef
    }
  } else {
    $package_url = undef
  }

  class { 'logstashforwarder':
    ensure        => present,
    init_template => 'profile/logstashforwarder/init_logstashforwarder.erb',
    package_url   => $package_url,
    manage_repo   => false,
    status        => 'enabled',
    autoupgrade   => false,
    configdir     => $configdir,
    servers       => [ "${logstash_host}:12002" ],
    ssl_ca        => "${settings::ssldir}/certs/ca.pem",
  }
}
