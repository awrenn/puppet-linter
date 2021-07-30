class profile::access::ghost (
  Boolean $allow_sudo = false,
) {
  Account::User <| groups == 'ghost-team' |>
  ssh::allowgroup { 'ghost-team': }

  if $allow_sudo {
    sudo::allowgroup { 'ghost-team': }
  }
}
