# Class: profile::pe::cd4peworker
#
# Manage the cd4pe worker host
#
class profile::pe::cd4peworker (
  Boolean $prune_images = true,
  Optional[String] $docker_version = undef,
){
  profile_metadata::service { $title:
    human_name        => 'Puppet Enterprise cd4pe worker',
    owner_uid         => 'erik.hansen',
    team              => dio,
    end_users         => ['notify-infracore@puppet.com'],
    escalation_period => 'global-workhours',
    downtime_impact   => "Can't make changes to infrastructure",
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/SRE+Internal+Puppet+Infrastructure+Service+Docs',
    ],
  }

  # This is needed so that private repos can be cloned as part of testing our control repo
  file {
    default:
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0600',
    ;
    '/root/.ssh/cd4pe_worker_id_rsa':
      content => lookup(cd4pe::worker_sshkey),
    ;
    '/root/.ssh/config':
      content => @(END),
        host github.com
          user git
          identityfile /root/.ssh/cd4pe_worker_id_rsa
          StrictHostkeyChecking no
        | END
    ;
  }

  class {'docker':
    ensure     => present,
    version    => $docker_version,
    log_driver => 'journald',
  }

  if $prune_images {
    cron { 'prune docker images':
      command => '/bin/docker image prune --force',
      user    => 'root',
      weekday => 0,
      hour    => 0,
      minute  => 30,
    }
  }
}
