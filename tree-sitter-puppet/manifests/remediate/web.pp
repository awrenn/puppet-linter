# == Class: profile::remediate::web
class profile::remediate::web {
  class { '::profile::nginx::proxy_ssl':
    hostname         => $facts['networking']['fqdn'],
    proxy_port       => 8443,
    proxy_scheme     => 'https',
    proxy_set_header => [
      'Host $host',
      'X-Real-IP $remote_addr',
      'X-Forwarded-For $proxy_add_x_forwarded_for',
      'X-Forwarded-Proto $scheme',
    ],
  }
}
