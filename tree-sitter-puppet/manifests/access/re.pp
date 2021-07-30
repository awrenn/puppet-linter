# Grant the Release Engineering team access
class profile::access::re {
  Account::User <| groups == 're' |>
  ssh::allowgroup { 're': }
  sudo::allowgroup { 're': }
}
