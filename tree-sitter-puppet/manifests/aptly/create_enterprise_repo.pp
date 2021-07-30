define profile::aptly::create_enterprise_repo (
  $architectures = ['amd64', 'i386'],
  $dists         = [],
) {

  $dists.each |String $dist| {
    aptly::repo { "${name}-${dist}":
      architectures => $architectures,
      comment       => "${name} repo",
      component     => "${dist}/main",
      distribution  => $dist,
      before        => File["/opt/enterprise/${name}/repos"],
    }
  }

  file { "/opt/enterprise/${name}/repos/debian":
    ensure => link,
    target => "/opt/tools/aptly/public/${name}",
  }
}
