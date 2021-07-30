# @summary Included from Class['role'] for every node
#
# @param sensitive_cyg_server_password
#   Only needed on Windows nodes. It doesn't do anything on other OSs.
class profile::base (
  Optional[Sensitive[String[1]]] $sensitive_cyg_server_password = undef,
) {

  include profile::os
  include profile::base::puppet
  include resource_api::agent
  include virtual::users

  if $facts['is_vagrant'] {
    include profile::vagrant
  }

  class { 'ssh::server':
    cyg_server_password => $sensitive_cyg_server_password,
  }
}
