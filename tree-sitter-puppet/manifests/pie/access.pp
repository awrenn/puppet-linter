# @summary Allow the pie team to ssh to a host
#
# Allow the pie team to ssh to a host
#
class profile::pie::access (
  $allow_sudo = false,
) {
  Account::User <| groups == 'pie-team' |>
  ssh::allowgroup { 'pie-team': }

  if $allow_sudo {
    sudo::allowgroup { 'pie-team': }
  }
}
