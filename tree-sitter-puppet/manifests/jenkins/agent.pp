# Class: profile::jenkins::agent
# Provision a Puppet Labs-approved Jenkins agent.
#
class profile::jenkins::agent (
  $master_url,
  $master_user,
  $sensitive_master_pass,
  $executors                 = (2 * $facts['processors']['count']),
  $labels                    = '',
  $agent_alias               = undef,
  $tmpclean_enabled          = true,
  $workspace_cleanup_enabled = true,
  $process_cleanup_enabled   = true,
  $jenkins_dir_only          = false,
  $install_agent_java11       = false,
  $set_metadata              = false,
  Array[String[1]] $doc_urls = ['https://confluence.puppetlabs.com/display/SRE/Jenkins+Instances'],
  $metadata_team             = undef,
  $metadata_human_name       = undef,
  $metadata_owner_uid        = undef,
){
  if $set_metadata {
    profile_metadata::service { $title:
      human_name => $metadata_human_name,
      team       => pick($metadata_team, $profile::monitoring::icinga2::common::owner),
      owner_uid  => $metadata_owner_uid,
      doc_urls   => $doc_urls,
    }
  }

  meta_motd::keyvalue { "Jenkins master: ${master_url}": }

  if $agent_alias {
    meta_motd::keyvalue { "Jenkins agent alias: ${agent_alias}": }
  }

  case $facts['kernel'] {
    'Darwin':  { include profile::jenkins::agent::darwin    }
    'Linux':   {
      if $jenkins_dir_only {
        include profile::jenkins::agent::linux::jenkins_dir
      } else {
        include profile::jenkins::agent::linux
      }
    }
    'windows': { include profile::jenkins::agent::windows   }
    default:   { fail("Kernel ${facts['kernel']} is not supported.") }
  }
}
