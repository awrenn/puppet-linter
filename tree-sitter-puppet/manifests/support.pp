# Give ssh and sudo access to support.
class profile::support {
  Account::User <| groups == 'support' |>
  ssh::allowgroup { 'support': }
  sudo::allowgroup { 'support': }
}
