# Grant various release tools access
#
# This is more than just the RE team. See profile::access::re.
class profile::access::release {
  Account::User <| groups == 'release' |>
  ssh::allowgroup { 'release': }
  sudo::allowgroup { 'release': }
}
