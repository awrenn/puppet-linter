# An OpenLDAP server
class profile::openldap {
  include profile::server
  include ssl

  meta_motd::register { 'OpenLDAP Server': }

  $ssl_name = $facts['networking']['domain'] ? {
      'ops.puppetlabs.net'      => 'wildcard.ops.puppetlabs.net',
      'delivery.puppetlabs.net' => 'wildcard.delivery.puppetlabs.net',
      default => fail("profile::openldap does not support domain '${facts['networking']['domain']}'"),
  }

  class { 'openldap::server':
    ca_cert_source   => "puppet:///modules/profile/ssl/${ssl_name}_inter.crt",
    ldap_cert_source => "puppet:///modules/profile/ssl/${ssl_name}.crt",
    ldap_key         => $ssl::keys[$ssl_name],
  }

  # Schema overrides. These are only used when a DB is being created.
  file { '/usr/local/openldap/etc/openldap/schema':
    owner   => 'ldap',
    group   => 'ldap',
    mode    => '0644',
    recurse => remote,
    source  => 'puppet:///modules/profile/openldap/schema',
    require => Class['::Openldap::Server::Install'],
  }

  logrotate::job { 'debug_openldap':
    log     => '/var/log/debug',
    options => [
      'rotate 1',
      'daily',
      'compress',
    ],
  }

  if $profile::server::fw {
    include profile::fw::ldap
  }

  if $profile::server::backups {
    include profile::openldap::backup
  }

}
