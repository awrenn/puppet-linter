# Puppet agent downloads server
class profile::delivery::agent_downloads {
  profile_metadata::service { $title:
    human_name        => 'Puppet agent downloads server',
    team              => 're',
    owner_uid         => 'bradejr',
    end_users         => ['pe-and-platform-program@puppet.com'],
    escalation_period => 'pdx-workhours',
    downtime_impact   => @(END),
      Enterprise CI / promotion workflows will fail if agent-downloads isn't accessible.
      | END
  }

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
