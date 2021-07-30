##
#
class profile::dev::admin {

  ssh::allowgroup { 'developers': }
  sudo::allowgroup { 'developers': }

  Account::User <| groups == 'developers' |>
  Group         <| title == 'developers' |>
}
