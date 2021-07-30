# Class: profile::ci::ops::access
#
# Grant access to the SysOps CI system
#
class profile::ci::ops::access (
  $allow_ssh = true,
  $allow_sudo = true,
) {
  Account::User <| title == 'opsjenkins' |>
  if $allow_ssh {
    ssh::allowgroup { 'opsjenkins': }
  }
  if $allow_sudo {
    sudo::allowgroup { 'opsjenkins': }
  }
}
