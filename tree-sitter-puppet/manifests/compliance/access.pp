# @summary Allow the compliance team to ssh to a host
#
# Allow the compliance team to ssh to a host
#
class profile::compliance::access (
  $allow_sudo = false,
) {
  Account::User <| groups == 'compliance' |>
  ssh::allowgroup { 'compliance': }

  if $allow_sudo {
    sudo::allowgroup { 'compliance': }
  }
}

