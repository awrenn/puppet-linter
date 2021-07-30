# Class: profile::prosvc
#
# Manage the access of the Professional Services Team
#
class profile::prosvc {

  Account::User <| groups == 'prosvc' |>

  ssh::allowgroup  { 'prosvc': }
  sudo::allowgroup { 'prosvc': }
}
