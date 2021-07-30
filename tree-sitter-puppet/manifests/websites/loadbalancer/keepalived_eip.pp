class profile::websites::loadbalancer::keepalived_eip (
  $auth_mode       = 'AH', # either AH or PASS
  $keepalived_pass = 'QcD5IIBi', # cannot exceed 8 characters
  $eip             = 'default',
  $keepalive_vrid  = '57',
  ){
  meta_motd::register { 'profile::websites::loadbalancer::keepalived_eip': }
  include profile::aws::common
  include profile::aws::cli

  validate_re($auth_mode, ['^AH$', '^PASS$'], 'auth_mode parameter must be AH or PASS')

  apt::pin { 'keepalived':
    originator => 'Debian',
    release    => "${facts['os']['distro']['codename']}-backports",
    codename   => "${facts['os']['distro']['codename']}-backports",
    priority   => 1000,
  }

  if $facts['os']['distro']['codename'] == 'jessie' {
    $keepalived_config = @(END)
      [Unit]
      Description=Keepalived VRRP High Availability Monitor
      After=syslog.target network.target

      [Service]
      ExecStart=/usr/sbin/keepalived --dont-fork --log-console
      ExecReload=/bin/kill -HUP $MAINPID
      TimeoutSec=10
      Restart=on-failure

      [Install]
      WantedBy=multi-user.target
      | END

    file { '/etc/systemd/system/keepalived.service':
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $keepalived_config,
      notify  => Service['keepalived'],
      before  => Service['keepalived'],
    }
  }

  package {'keepalived':
    ensure => 'present',
  }
  service {'keepalived':
    ensure    => 'running',
    enable    => true,
    hasstatus => false,
    require   => Package['keepalived'],
  }

  validate_string($keepalived_pass)

  $keepalive_node_query = puppetdb_query("inventory {
    facts.classification.group    = '${facts['classification']['group']}' and
    facts.classification.stage    = '${facts['classification']['stage']}' and
    facts.classification.function = '${facts['classification']['function']}' and
    facts.whereami                = '${facts['whereami']}' and
    resources {
      type = 'Class' and
      title = 'Profile::Websites::Loadbalancer::Keepalived_eip'
    }
  }")

  $keepalive_node_ips   = sort(unique($keepalive_node_query.map |$value| { $value['facts']['networking']['ip'] }))
  $keepalive_node_fqdns = sort(unique($keepalive_node_query.map |$value| { $value['facts']['networking']['fqdn'] }))

  if is_array($keepalive_node_fqdns) {
    $keepalive_nodes = $keepalive_node_fqdns
  } else {
    $keepalive_nodes = []
  }

  if count($keepalive_nodes) < 2 {
    notify{'profile::websites::loadbalancer::keepalived found < 2 keepalive nodes; this is expected while bootstrapping a pair but indicates a problem otherwise': }
  }

  # determine which LB should be the keepalived master
  # it doesn't matter which node it is as long as only one is selected
  if count($keepalive_nodes) == 0 {
    # if no nodes were found in puppetdb, this must be bootstrapping a pair
    notify { "bootstrapping keepalive pair with ${facts['networking']['fqdn']} as keepalive master": }
    $keepalive_master = $facts['networking']['fqdn']
  } else {
    $keepalive_master = $keepalive_nodes[0]
  }
  if (count($keepalive_nodes) == 1) and $keepalive_nodes[0] == $facts['networking']['fqdn'] {
    notify { 'Warning: this node is a keepalive master but no backup nodes were found in puppetdb': }
  }

  # only one balancer member should be primary
  # all other members should be backup and only used if the first is down
  $keepalived_role = $facts['networking']['fqdn'] ? {
    $keepalive_nodes[0] => 'MASTER',
    default             => 'BACKUP',
  }

  $unicast_peer_ips = delete($keepalive_node_ips, $facts['networking']['ip'])
  $keepalived_priority = $keepalived_role ? {
    'MASTER' => 110,
    default  => 100 - $facts['classification']['number'],
  }

  file { '/etc/keepalived/keepalived.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('profile/websites/loadbalancer/keepalived.conf.erb'),
    notify  => Service['keepalived'],
    before  => Service['keepalived'],
  }

  # this script is run by keepalive when the node is promoted to master
  # it takes over the elastic IP address
  file { '/etc/keepalived/master.sh':
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    content => template('profile/websites/loadbalancer/eip_master.sh.erb'),
    before  => Service['keepalived'],
  }

  if $profile::server::params::fw {
    each($unicast_peer_ips) |$peer_ipaddress| {
      firewall { "130 allow vrrp/keepalived from ${peer_ipaddress} in ${facts['classification']['group']} ${facts['classification']['stage']}}":
        proto  => 'vrrp',
        action => 'accept',
        source => $peer_ipaddress,
      }
    }
  } else {
    notify {'Warning: profile::websites::loadbalancer::keepalived does not have a firewall enabled': }
  }

}
