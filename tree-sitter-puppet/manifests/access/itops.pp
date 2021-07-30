# Grant the ITOps team access
class profile::access::itops {
  Account::User <| groups == 'itops' |>
  ssh::allowgroup { 'itops': }
  sudo::allowgroup { 'itops': }
}
