# Class: profile::pe::master_common::autosign
#
# Configure the autosign gem on a PE master. This allows for token-based autosigning. This class needs to be included on
# all masters in order for the gen_autosign_token() puppet function to work.
#
# @param $jwt_token_secret [String[1]] The secret key used to generate tokens.
# @param $puppet_user [String[1]] The puppet user, used for setting file ownership, etc.
# @param $puppet_group [String[1]] The puppet group, used for setting file ownership, etc.
#
class profile::pe::master_common::autosign (
  String[1] $jwt_token_secret = undef,
  String[1] $puppet_user = 'pe-puppet',
  String[1] $puppet_group = 'pe-puppet',
){

  # This is needed for any master you wish to generate tokens on.
  class { 'autosign':
    ensure  => '0.1.3',
    user    => $puppet_user,
    group   => $puppet_group,
    config  => {
      'general'   => {
        'loglevel' => 'INFO',
      },
      'jwt_token' => {
        'secret'   => $jwt_token_secret,
        'validity' => '7200',
      },
    },
    require => Package['pe-puppetserver'],
  }

  # Prevent a duplicate declaration when run on a compiler.
  if $facts['classification']['function'] == 'master' or $facts['classification']['function'] == 'mom' {
    file { '/var/log/autosign.log':
      ensure => file,
      owner  => $puppet_user,
      group  => $puppet_group,
      mode   => '0640',
    }
  }

  ini_setting { 'pe_autosign_policy':
    ensure  => present,
    value   => '/opt/puppetlabs/puppet/bin/autosign-validator',
    setting => 'autosign',
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'master',
  }
}
