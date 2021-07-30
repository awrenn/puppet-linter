# @summary Allow the modules team to ssh to a host
#
# Allow the modules team to ssh to a host
#
class profile::modules::access (
  $allow_sudo = false,
) {
  Account::User <| groups == 'modules' |>
  ssh::allowgroup { 'modules': }

  if $allow_sudo {
    sudo::allowgroup { 'modules': }
  }
}
