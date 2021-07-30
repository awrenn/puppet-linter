# Grant the admins of pebuildinfo access
class profile::pebuildinfo::access {
  Account::User <| groups == 'pebuildinfo-admins' |>
  ssh::allowgroup { 'pebuildinfo-admins': }
  sudo::allowgroup { 'pebuildinfo-admins': }
}
