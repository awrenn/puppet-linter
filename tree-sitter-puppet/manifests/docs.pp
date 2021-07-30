# Manage access of the docs team

class profile::docs {
  include virtual::users
  Account::User <| groups == 'docs' |>
  Group         <| title == 'docs' |>

  # Allow docs group to gain shell
  ssh::allowgroup  { 'docs': }

  # Allow docs group to gain root
  sudo::allowgroup { 'docs': }
}
