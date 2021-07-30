# Class: profile::base::puppet::params
#
# Params class for profile::base::puppet
#
# TODO: replace this with data provider :)
#
class profile::base::puppet::params {
  $ca_server = $::settings::ca_server

  $server = lookup(profile::base::puppet::pe_master)

  $confdir = $facts['os']['family'] ? {
    'windows' => $facts['os']['release']['full'] ? {
      '2003'  => 'c:/documents and settings/all users/application data/puppetlabs/puppet/etc',
      default => 'c:/programdata/puppetlabs/puppet/etc',
    },
    default   => '/etc/puppetlabs/puppet',
  }

  $manage_package = $facts['os']['name'] ? {
    'CumulusLinux' => false,
    default        => true,
  }

  # We put the Solaris packages into our main IPS repo, so we don't want the puppet_agent module managing that.
  $manage_repo = $facts['os']['family'] ? {
    'Solaris' => false,
    default   => true,
  }

  $package_version = pe_compiling_server_aio_build()

  $splay = false
}
