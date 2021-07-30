# Settings for a build node that has been granted access to Puppet DB
class profile::dio::pdbaccess {
  file {
    default:
      ensure => file,
      group  => 'jenkins',
      mode   => '0640',
      owner  => 'jenkins',
    ;
    '/pdbaccess':
      ensure => directory,
      mode   => '0750',
    ;
    '/pdbaccess/puppet-ca.pem':
      source => '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
    ;
    '/pdbaccess/puppet-cert.pem':
      source => "/etc/puppetlabs/puppet/ssl/certs/${facts['networking']['fqdn']}.pem",
    ;
    '/pdbaccess/puppet-key.pem':
      mode   => '0640',
      source => "/etc/puppetlabs/puppet/ssl/private_keys/${facts['networking']['fqdn']}.pem",
    ;
  }

  vcsrepo { '/pdbaccess/hiera-to-pql':
    ensure   => present,
    provider => git,
    owner    => 'jenkins',
    user     => 'jenkins',
    source   => 'git@github.com:puppetlabs/hiera-to-pql.git',
    revision => 'f41d69742dffc39650fe3e3f5e3a74df775eb6ce',
  }
}
