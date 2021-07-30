class profile::logging::rsyslog::server {

  $ssldir = '/etc/puppetlabs/puppet/ssl'

  class { '::rsyslog::server':
    enable_udp => true,
    server_dir => '/srv/log/',
    ssl        => true,
    ssl_ca     => "${ssldir}/certs/ca.pem",
    ssl_cert   => "${ssldir}/certs/${facts['networking']['fqdn']}.pem",
    ssl_key    => "${ssldir}/private_keys/${facts['networking']['fqdn']}.pem",
  }

}
