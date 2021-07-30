# A profile to setup a firewall for postgresql
class profile::postgresql::firewall (
  $postgres_port = '5432',
  $allow_range   = undef,
) {
  include profile::server::params

  if $::profile::server::params::fw == true {
    if $allow_range == undef {
      firewall { '103 allow postgres':
        proto  => 'tcp',
        action => 'accept',
        dport  => $postgres_port,
      }
    }
    else {
      firewall { '103 allow postgres':
        proto  => 'tcp',
        action => 'accept',
        dport  => $postgres_port,
        source => $allow_range,
      }
    }
  }
  else {
    notice { 'Profile::postgresql::firewall is included but profile::server::params::fw is not set to true!': }
  }
}
