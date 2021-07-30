# Configuration for all nodes in delivery.puppetlabs.net
#
# Do not rely on this for new nodes. Set `profile::delivery::legacy: false` in
# hiera, and include appropriate profiles in your role, including
# `profile::server` and a profile that grants access, e.g.
# `profile::access::re`.
class profile::delivery (
  Boolean $legacy = true,
) {
  if $legacy {
    # profile::server doesn't completely support Windows and OS X.
    if $facts['os']['family'] != 'windows' and $facts['os']['family'] != 'Darwin' {
      include profile::metrics
      include profile::server
    }

    include profile::access::re
    include profile::access::release
  }
}
