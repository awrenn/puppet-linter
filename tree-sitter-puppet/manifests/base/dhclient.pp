class profile::base::dhclient {

  include dhclient::params

  # Only include dhclient if the module supports the current operating system
  if $::dhclient::params::package {

    include dhclient

    dhclient::statement { 'option rfc3442-classless-static-routes code 121 = array of unsigned integer 8': order => 10}
    dhclient::statement { "send host-name ${facts['networking']['hostname']}": order => 20 }
    dhclient::statement { 'Specify dhcp request fields':
      content => [
        "request broadcast-address,\n",
        "domain-name,\n",
        "domain-name-servers,\n",
        "domain-search,\n",
        "host-name,\n",
        "interface-mtu,\n",
        "netbios-name-servers,\n",
        "netbios-scope,\n",
        "ntp-servers,\n",
        "rfc3442-classless-static-routes,\n",
        "routers,\n",
        "subnet-mask,\n",
        'time-offset',
      ],
      order   => 25,
    }
    # Linode's DHCP assigns a linode-specific domain name
    # since we only host systems with the puppetlabs.com domain there, this is
    # a hack to prevent domain from breaking
    if $::whereami =~ /^linode/ {
      dhclient::statement {"supersede domain-name \"puppetlabs.com\"":}
      dhclient::statement {'supersede domain-name-servers 8.8.8.8':}
    }
  }
}
