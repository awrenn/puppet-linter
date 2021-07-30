# Grant access to BizOps
class profile::bizops {
  include virtual::users
  Account::User <| groups == 'bizops' |>
  Group         <| title == 'bizops' |>

  ssh::allowgroup  { 'bizops': }
  sudo::allowgroup { 'bizops': }
}
