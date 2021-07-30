# Configure Solaris
class profile::os::solaris (
  Boolean $static_dns = false,
) {
  if $facts['kernelrelease'] != '5.11' {
    fail('The Solaris profile only supports Solaris 11')
  }

  include profile::server::params
  include profile::os::solaris::oracle_certs
  include profile::os::solaris::scsi_vhci
  include profile::os::solaris::sas2ircu
  include profile::os::solaris::system_conf
  include profile::os::splatnix
  include profile::pypi
  include puppetlabs::scripts
  include ruby

  augeas { 'enable autofs home directories':
    context => '/files/etc/auto_home',
    changes => [
      'ins 01 before *[map = "auto_home"]',
      'set 01 "*"',
      'set 01/location/1/host "localhost"',
      'set 01/location/1/path "/export/home/&"',
    ],
    onlyif  => 'match */location/*[path = "/export/home/&"] size == 0',
  }

  service { 'system/manifest-import:default': enable => true }

  file {
    '/root/.hushlogin':
      ensure  => present,
      content => ' ';
    '/usr/bin/puppet':
      ensure => link,
      target => '/opt/puppetlabs/bin/puppet';
    '/usr/bin/facter':
      ensure => link,
      target => '/opt/puppetlabs/bin/facter';
  }

  if $profile::server::params::monitoring {
    include profile::os::solaris::monitor
  }

  if $facts['virtual'] != 'zone' {
    # We mirror all the Oracle repos we use.
    $publishers = ['plops', 'puppetlabs.com', 'solaris', 'solarisstudio' ]

    $publishers.each |$publisher| {
      pkg_publisher { $publisher:
        ensure => present,
        origin => "http://repo-ips1-prod.ops.puppetlabs.net:9001/${publisher}",
        enable => true,
      }
    }

    Pkg_publisher<||> -> Package<||>
  }

  if $static_dns {
    dns { 'anycasted dns':
      nameserver => lookup('profile::network::nameservers'),
      domain     => lookup('profile::network::default_domain'),
    }
  }

}
