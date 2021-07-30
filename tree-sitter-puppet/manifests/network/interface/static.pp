# site/profile/manifests/network/interface/static.pp
class profile::network::interface::static {

  if $facts['os']['family'] == 'Debian' {
    $interfaces = hiera('profile::network::interfaces', {})
    $interfaces.each |$int, $data| {
      augeas{ "${int}_interface":
        context => '/files/etc/network/interfaces',
        changes => [
          "set auto[child::1 = '${int}']/1 ${int}",
          "set iface[. = '${int}'] ${int}",
          "set iface[. = '${int}']/family inet",
          "set iface[. = '${int}']/method static",
          "set iface[. = '${int}']/address ${data['address']}",
          "set iface[. = '${int}']/netmask ${data['netmask']}",
          "set iface[. = '${int}']/gateway ${data['gateway']}",
        ],
      }
    }
  } else {
    notify { "Unsupported osfamily ${facts['os']['family']}": }
  }
}
