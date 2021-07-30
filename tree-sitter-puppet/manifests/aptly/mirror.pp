# Set up a mirror in aptly and schedule updates every two hours
define profile::aptly::mirror (
  String[1] $location,
  String[1] $release,
  String[1] $key,
  String[1] $keyserver = 'hkps.pool.sks-keyservers.net',
  Array[String[1]] $architectures = [],
  Array[String[1]] $repos = [],
  # Repos to automatically import into:
  Array[String[1]] $into_repos = [],
) {
  include profile::aptly

  aptly::mirror { $name:
    location      => $location,
    release       => $release,
    key           => {
      id     =>  $key,
      server => $keyserver,
    },
    architectures => $architectures,
    repos         => $repos,
  }

  $mirror_log = $::profile::aptly::log_format.sprintf("mirror-update.${name}")
  $arguments = shellquote($name, $into_repos).regsubst('%', '\%', 'G')
  cron { "aptly mirror update ${name}":
    command => "/usr/local/bin/aptly-update-mirror.sh ${arguments} > ${mirror_log} 2>&1",
    user    => 'aptly',
    hour    => '*/2',
    minute  => fqdn_rand(60, $name),
    require => flatten([
      Aptly::Mirror[$name],
      $into_repos.map |$repo| { Aptly::Repo[$repo] }
    ]),
  }
}
