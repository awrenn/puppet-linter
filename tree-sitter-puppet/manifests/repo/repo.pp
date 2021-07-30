# defined type to create package repositories
#
define profile::repo::repo (
  $repo_types = ['yum'],
  $description = "${name} repository created using profile::repo::repo",
) {

  $repo_path = "/opt/repos/${name}"
  $repo_cache_path = "/opt/repo_cache/${name}"

  # Basically mkdir -p
  $repo_path_parts = split($repo_path, '/').delete('')
  $repo_paths = $repo_path_parts.reduce([]) |$result, $value| {
    $result + ["${result[-1]}/${value}"]
  }.delete('/opt')

  $repo_cache_path_parts = split($repo_cache_path, '/').delete('')
  $repo_cache_paths = $repo_cache_path_parts.reduce([]) |$result, $value| {
    $result + ["${result[-1]}/${value}"]
  }.delete('/opt')

  # Filter out possible duplicates
  $repo_dirs = unique($repo_paths + $repo_cache_paths)

  $repo_dirs.each |$dir| {
    if ! defined(File[$dir]) {
      file { $dir:
        ensure => directory,
        mode   => '0750',
        owner  => 'root',
        group  => 'www-data',
      }
    }
  }

  if 'yum' in $repo_types {
    exec { "create ${name} repo":
      command => "/usr/bin/createrepo --content '${description}' --database ${repo_path}",
      creates => "${repo_path}/repodata",
    }

    exec { "update ${name} repo":
      command => "/usr/bin/createrepo --content '${description}' --cachedir ${repo_cache_path} --update ${repo_path}",
      onlyif  => "[ -d ${repo_path}/repodata ] && [ -f ${repo_path}/.rebuild ]",
    }

    file { "${repo_path}/.rebuild":
      ensure  => absent,
      require => Exec["update ${name} repo"],
    }
  }

  if 'apt' in $repo_types {
    notify {'apt repo support not implemented yet': }
  }
}
