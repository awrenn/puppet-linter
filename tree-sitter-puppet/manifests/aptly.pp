# Aptly APT repo management
class profile::aptly (
  # Default list of architectures
  Array[String[1]] $architectures = [],
) {
  include profile::apt

  $repos_path = '/srv/aptly/repos'
  $keys_path = '/srv/aptly/keys'
  $log_format = '/var/log/aptly/%s.$(date +"\%%Y-\%%m-\%%d_\%%H:\%%M:\%%S").log'

  # This cannot be required by ::aptly because of a dependency loop.
  Account::User <| title == 'aptly' |>

  class { '::aptly':
    config => {
      rootDir       => $repos_path,
      architectures => $architectures,
    },
    user   => 'aptly',
  }

  $command = $::aptly::aptly_cmd

  ensure_packages(['gnupg'])

  file {
    default:
      ensure => directory,
      owner  => 'aptly',
      group  => 'aptly',
    ;
    ['/srv/aptly', $repos_path, '/var/log/aptly']:
      mode   => '0755',
    ;
    $keys_path:
      mode    => '0500',
      purge   => true,
      recurse => true,
      force   => true,
    ;
  }

  file { '/usr/local/bin/aptly-ssh-handler.py':
    ensure => file,
    owner  => 'root',
    group  => '0',
    mode   => '0555',
    source => 'puppet:///modules/profile/aptly/aptly-ssh-handler.py',
  }

  profile::rotate_files { '/var/log/aptly/*':
    user => 'aptly',
  }
}
