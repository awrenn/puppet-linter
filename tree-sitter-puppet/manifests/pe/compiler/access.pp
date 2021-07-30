# Add Puppet Server devs to the PE compilers.
#
class profile::pe::compiler::access {
  Account::User <| groups == 'puppet-server' |>
  ssh::allowgroup { 'puppet-server': }
  sudo::allowgroup { 'puppet-server': }
}
