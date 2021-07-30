# Class: profile::openldap::backup
#
# Manage the backup of OpenLDAP servers
#
class profile::openldap::backup {
  $backup_directory = '/var/backups/openldap'
  $databases = [
    'cn=config',
    'dc=puppetlabs,dc=com',
  ]

  $hour   = [0, 4, 8, 12, 16, 20]
  $minute = 15

  file { '/var/backups':
    ensure => directory,
    owner  => 'root',
    group  => '0',
    mode   => '0755',
  }

  file { $backup_directory:
    ensure => directory,
    owner  => 'root',
    group  => '0',
    mode   => '0700',
  }

  $databases.each |$d| {
    $r        = regsubst($d, '(=|,)', '_', 'G')
    $filename = "${backup_directory}/${d}.ldif"

    cron { "backup_openldap_${d}":
      command => [
        'umask 0077',
        "/bin/rm -f ${filename}",
        "/usr/local/openldap/sbin/slapcat -b '${d}' -l ${filename}",
      ].join(' && '),
      user    => 'root',
      hour    => $hour,
      minute  => $minute,
    }
  }
}
