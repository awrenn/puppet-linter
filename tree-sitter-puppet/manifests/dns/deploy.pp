# Class: profile::dns::deploy
# Sets up a net server to deploy DNS zones.
#
class profile::dns::deploy {

  include bind::params
  include profile::jenkins::params

  $agent_home = $profile::jenkins::params::agent_home

  exec { 'ensure dns-zone repo exists':
    path    => ['/usr/bin', '/usr/local/bin'],
    command => 'git clone git@git.puppetlabs.net:puppetlabs-dnszones.git /opt/dns',
    creates => '/opt/dns/.git',
  }

  # Creates Jenkins user and adds SSH credentials
  Account::User <| tag == 'jenkins' |>

  file {
    default:
      owner   => $profile::jenkins::params::jenkins_owner,
      group   => $profile::jenkins::params::jenkins_group,
      require => Account::User[$profile::jenkins::params::jenkins_owner],
    ;
    "${agent_home}/.ssh":
      ensure => directory,
      mode   => '0700',
    ;
    "${agent_home}/.ssh/authorized_keys":
      ensure  => file,
      mode    => '0640',
      content => "${lookup('profile::jenkins::agent::id_rsa_jenkins_pub')}\n",
    ;
  }

  ssh::allowgroup { 'jenkins': }

  sudo::entry { 'deploy dns':
    entry => '%jenkins ALL=(ALL) NOPASSWD: /usr/local/sbin/dnsscript.sh',
  }

  file{ '/usr/local/sbin/dnsscript.sh':
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/mrepo_service/dns/dnsscript.sh',
  }
}
