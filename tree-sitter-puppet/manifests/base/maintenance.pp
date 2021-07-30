# This class deploys a fact that declares whether a system
# can be brought down for maintenance automatically, or if
# a maintenance window must be scheduled.
#
class profile::base::maintenance (
  $allow_restart = false
) {

  if $allow_restart == false {
    $allow_restart_message = 'false'
  } else {
    $allow_restart_message = $allow_restart
  }

  file { '/opt/puppetlabs/facter/facts.d/allow_restart.txt':
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    content => "allow_restart=${allow_restart_message}\n",
  }
}
