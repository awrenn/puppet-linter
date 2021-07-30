# Delete oldest files when more than $keep exist
#
# Note that if you change $name, the old cron job will not be removed. You must
# use ensure => absent, or set `profile::base::purge_cron: true` in hiera.
#
# Parameters:
#   [*glob*]   - (namevar) The glob matching the files to manage.
#   [*keep*]   - Number of files to keep.
#   [*user*]   - User to remove files as.
#   [*hour*]   - Hour at which to run (cron format).
#   [*minute*] - Minute at which to run (cron format).
define profile::rotate_files (
  String $glob = $name,
  Integer[0] $keep = 7,
  String $user = 'root',
  Variant[String, Integer] $hour = 2,
  Variant[String, Integer] $minute = fqdn_rand(59),
) {
  $offset = $keep + 1
  # clean up cron job from previous defined type
  cron { "backup::rotate[${name}]: delete all but the newest": ensure => absent, }

  cron { "profile::rotate_files[${name}]: delete all but the newest":
    command => [
        "/bin/ls -1td ${glob}",
        "/usr/bin/tail -n +${offset}",
        '/usr/bin/tr "\n" "\0"',
        '/usr/bin/xargs -0 /bin/rm -R',
      ].join(' | '),
    user    => $user,
    hour    => $hour,
    minute  => $minute,
  }
}
