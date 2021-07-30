#Grants access to puppet-admins
class profile::puppetadmins (
  $allow_ssh  = false,
  $allow_sudo = false,
) {
  Account::User <| groups == 'puppet-admins' |>

  if $allow_ssh {
  ssh::allowgroup  { 'puppet-admins': }
  }
  if $allow_sudo {
  sudo::allowgroup { 'puppet-admins': }
  }
}
