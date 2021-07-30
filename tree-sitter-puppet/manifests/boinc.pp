# Profile to setup a BOINC client
class profile::boinc (
  #
) {
  profile_metadata::service { $title:
    human_name        => 'BOINC Client',
    owner_uid         => 'gene.liverman',
    end_users         => ['gene.liverman@puppet.com'],
    escalation_period => 'pdx-workhours',
    downtime_impact   => 'We stop chewing on data for science',
    notes             => @("NOTES"),
      This profile setups up a server to participate in scientific research.
      Currently, research is done using Gene's account.
      |-NOTES
  }

  case $facts['os']['name'] {
    'Debian': {
      package { ['boinc-client', 'boinctui']:
        ensure => latest,
        before => Service['boinc-client'],
      }

      service { 'boinc-client':
        ensure => running,
        enable => true,
      }
    }
    default: {
      fail("${facts['os']['name']} isn't supported yet")
    }
  }
}
