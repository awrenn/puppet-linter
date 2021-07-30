##
#
class profile::filer (
  $zvols    = undef,
  $storage1 = '10.32.92.0/24',
  $storage2 = '10.32.96.0/24'
) {
  profile_metadata::service { $title:
    human_name        => 'Storage for our VMware clusters',
    owner_uid         => 'gene.liverman',
    team              => dio,
    escalation_period => '24/7',
    downtime_impact   => 'All VMware VMs go down. Services throughout the company stop.',
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/Storage',
    ],
  }

  include profile::server

  if $::profile::server::monitoring {
    include profile::filer::monitor
  }

  $allow_ip = [ $storage1, $storage2 ]

  if $zvols {
    each($zvols) |$z| {
      zfs { $z:
        ensure   => present,
        sharenfs => 'on',
      }

      zfs_share { $z:
        sec_none_rw => $allow_ip,
      }

      file { "/${z}":
        owner => 'nobody',
        group => 'nobody',
        mode  => '0755',
      }
    }
  }
}
