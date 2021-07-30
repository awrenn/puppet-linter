# Grant the Development Infrastructure and Operations team access
class profile::access::dio {
  Account::User <| groups == 'dio' |>
  ssh::allowgroup { 'dio': }
  sudo::allowgroup { 'dio': }
}
