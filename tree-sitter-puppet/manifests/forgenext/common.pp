class profile::forgenext::common {
  include hosts
  include bundler
  include git # needed by rbenv module

  Account::User <| groups == 'forge-admins' |>
  Group         <| title  == 'forge-admins' |>

  # Allow SSH: forge-admins group
  ssh::allowgroup { 'forge-admins': }

  # Allow full sudo: forge-admins group
  sudo::allowgroup { 'forge-admins': }
}
