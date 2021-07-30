# profile::consul::agent
#
class profile::consul::agent (
  Boolean $enable = true,
) {
  if $enable {
    include profile::consul
  }
}
