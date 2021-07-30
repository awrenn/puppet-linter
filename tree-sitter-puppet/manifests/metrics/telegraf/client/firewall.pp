# Firewall rule for Telegraf's Prometheus metrics endpoint
class profile::metrics::telegraf::client::firewall {
  $_source_ip = $facts['whereami'] ? {
    /^linode.*/ => '192.69.65.0/24',
    default     => undef,
  }

  case $facts['kernel'] {
    'Linux': {
      firewall { '301 allow telegraf prometheus endpoint':
        proto  => 'tcp',
        action => 'accept',
        dport  => 9273,
        source => $_source_ip,
      }
    }
    'windows': {
      include windows_firewall

      # we don't have any Linodes running Windows so this resource does not
      # worry about setting remote_ip.
      windows_firewall::exception { "Allow Telegraf's Prometheus endpoint":
        ensure      => present,
        enabled     => true,
        direction   => 'in',
        action      => 'allow',
        protocol    => 'TCP',
        remote_port => 'any',
        local_port  => 9273,
      }
    }
    default: {}
  }
}
