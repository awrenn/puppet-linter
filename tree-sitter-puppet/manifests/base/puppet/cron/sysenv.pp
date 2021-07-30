# Set up the puppet-cron.py script and cron job on "other" OSs.
#
# This is what runs puppet regularly.
#
# "Other" OSs include platforms Go doesn't run on like SPARC Solaris.
class profile::base::puppet::cron::sysenv (
  Variant[Enum['*'], Integer[0,23], Array[Integer[0,23]]] $cron_hour = '*',
  Variant[Integer[0,59], Array[Integer[0,59]]] $cron_minute = [fqdn_rand($run_interval), fqdn_rand($run_interval) + $run_interval],
) {
  # puppet/python only supports Linux, so we can't create a virtualenv.

  file {
    default:
      owner => 'root',
      group => 'root',
      mode  => '0555',
    ;
    '/opt/puppet-cron':
      ensure => directory,
    ;
    '/opt/puppet-cron/puppet-cron.py':
      ensure => file,
      source => 'puppet:///modules/profile/base/puppet/puppet-cron.py',
    ;
  }

  cron { 'pe agent':
    ensure  => present,
    command => 'PATH=/usr/bin:/bin:/usr/local/bin /opt/puppet-cron/puppet-cron.py',
    minute  => $cron_minute,
    hour    => $cron_hour,
  }
}
