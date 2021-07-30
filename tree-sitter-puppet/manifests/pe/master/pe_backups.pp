# Class: profile::pe::master::pe_backups
#
# Configure backups for the PE Master of Masters.  This uses the built-in puppet-backups functionality.
#
class profile::pe::master::pe_backups (
) {
  $pdb_backup_path = '/var/puppetlabs/backups'
  $pdb_lock_path = '/var/local/backup/pe/pe_backup.sh.lock'

  file {
    default:
      ensure => directory,
      group  => 'root',
    ;
    '/var/local/backup':
      owner => 'root',
      mode  => '0755',
    ;
    '/var/local/backup/pe':
      owner => 'root',
      mode  => '0700',
    ;
  }

  file { '/usr/local/bin/pe_backup.sh':
    ensure  => file,
    content => epp('profile/pe/master/backups/pe_backup.sh.epp', {
      backup_path => $pdb_backup_path,
      lock_path   => $pdb_lock_path,
    }),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  }

  cron { '/usr/local/bin/pe_backup.sh':
    command => '/usr/local/bin/pe_backup.sh',
    user    => 'root',
    hour    => 0,
    minute  => fqdn_rand(60),
    require => [
      File['/var/local/backup'],
      File['/usr/local/bin/pe_backup.sh'],
    ],
  }

}
