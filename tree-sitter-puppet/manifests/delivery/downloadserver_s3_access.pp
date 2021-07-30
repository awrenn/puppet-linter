# Puppet agent downloads server
class profile::delivery::agent_downloads {
  meta_motd::register { 'Puppet agent downloads server (profile::delivery::agent_downloads)': }

  include nginx

  $nodes   = puppetdb_query("inventory {
    facts.classification.stage = 'dev' and
    resources {
      type = 'Class' and
      title = 'Profile::Delivery::Agent_downloads'
    }
  }").map |$value| { $value['facts']['networking']['ip'] }
  $map_ips = $nodes.map |$n| { "${n}/32" }

  $mount_dir = '/srv/backup'
  $job_name  = 'agent_downloads'
  $mount     = "${mount_dir}/${job_name}"

  if $facts['classification']['stage'] == 'dev' {
    include profile::nfs::client

    file { [ $mount_dir, $mount ]:
      ensure => directory,
    }

    mount { $mount:
      ensure  => present,
      fstype  => 'nfs',
      target  => '/etc/fstab',
      options => 'ro',
      device  => join( [
        'stor-backup1-prod.ops.puppetlabs.net',
        '/backup-tank/backup/weth.delivery.puppetlabs.net_agent_downloads',
      ], ':'),
    }
  }
}
