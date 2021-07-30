# Update /etc/motd with information about the host
#
# It is sometimes useful to disable changes to /etc/motd when comparing runs in
# different environments. To do that:
#
#   sudo FACTER_suppress_motd=true puppet agent --test ...
class profile::motd {
  case $settings::server {
    /infranext/: { $motd_template = 'meta_motd/colossal-puppet-dag.epp' }
    default:     { $motd_template = 'meta_motd/short-puppet.epp' }
  }

  class { 'meta_motd':
    epp_template => $motd_template,
    epp_params   => {
      roles    => lookup('classes', Array[String], 'unique', []),
      location => $facts['whereami'],
    },
  }
}
