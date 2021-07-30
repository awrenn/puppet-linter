class profile::metrics::telegraf::client (
  Sensitive[Hash]            $sensitive_outputs,
  String[2]                  $agent_interval = '30s',
  Hash                       $tags = {},
) {
  $standard_tags = {
    'facter_current_environment'          => $facts['current_environment'],
    'facter_dmi_manufacturer'             => $facts['dmi']['manufacturer'],
    'facter_dmi_product_name'             => $facts['dmi']['product']['name'],
    'facter_os_family'                    => $facts['os']['family'],
    'facter_os_name'                      => $facts['os']['name'],
    'facter_os_release_full'              => $facts['os']['release']['full'],
    'facter_puppetversion'                => $facts['puppetversion'],
    'facter_virtual'                      => $facts['virtual'],
    'facter_whereami'                     => $facts['whereami'],
  }

  $combined_tags = $standard_tags + $tags

  $_logfile_location = $facts['kernel'] ? {
    'Linux'   => '/var/log/telegraf/telegraf.log',
    'windows' => "${facts['windows_env']['SYSTEMDRIVE']}\\\\Program Files\\\\telegraf\\\\telegraf.log",
  }

  class { 'telegraf':
    ensure                 => latest,
    hostname               => $facts['networking']['fqdn'],
    logfile                => $_logfile_location,
    interval               => $agent_interval,
    flush_interval         => $agent_interval,
    outputs                => unwrap($sensitive_outputs),
    global_tags            => $combined_tags,
    purge_config_fragments => true,
  }

  $_services = pick_default(fact('profile_metadata.services'), [])
  $_meta = {
    'escalation_period' => profile::metadata_combiner($_services, 'escalation_period'),
    'owner_uid'         => profile::metadata_combiner($_services, 'owner_uid'),
    'team'              => profile::metadata_combiner($_services, 'team'),
  }

  consul::service { 'prometheus-endpoint':
    address => $facts['networking']['ip'],
    port    => 9273,
    checks  => [
      {
        http     => "http://${facts['networking']['ip']}:9273/metrics",
        interval => '10s',
      },
    ],
    tags    => [
      "stage-${facts['classification']['stage']}",
    ],
    meta    => delete_undef_values($_meta),
    notify  => Service['consul'],
  }

  unless $facts['kernel'] == 'windows' {
    include profile::metrics::telegraf::client::splatnix_common
  }

  case $facts['kernel'] {
    'Linux': { include profile::metrics::telegraf::client::linux }
    'windows': { include profile::metrics::telegraf::client::windows }
  }
}
