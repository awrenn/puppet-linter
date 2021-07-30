##
#
class profile::metrics(
  Boolean $enable_diamond = true,
  Boolean $enable_prometheus = true,
) {

  unless $facts["whereami"] == 'aws_internal_net_vpc' or $enable_diamond == false {
    if $facts['os']['name'] in ['Debian', 'Solaris', 'CentOS'] {
      include profile::metrics::diamond::client
      include profile::python::packages
    }

    if $facts['os']['name'] == 'Centos' {
      Package <| title == 'diamond' |> { name => 'python-diamond' }
    }
  }

  if $enable_prometheus {
    case $facts['kernel'] {
      'Darwin': {
        # Telegraf works on Darwin but the Puppet module currently does not
      }
      'Linux': {
        include profile::consul::agent
        include profile::metrics::telegraf::client
      }
      'SunOS': {
        # Telegraf is not listed as working on Solaris.
        # https://github.com/vikramjakhr/telegraf-solaris may be a good option here.
        # The Prometheus node_exporter does get some basic ones if we want to use that.
        # Alternatively, collectd does work and seems to be supported by puppet/collectd
      }
      'windows': {
        include profile::consul::agent
        include profile::metrics::telegraf::client
      }
      default: {
        # AIX hosts would hit this block.
        # It seems that collectd can be compiled for AIX so that might work if needed.
      }
    }

    if $profile::server::fw {
      include profile::metrics::telegraf::client::firewall
    }
  }
}
