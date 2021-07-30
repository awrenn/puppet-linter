class profile::docker::registry (
  String $user = 'jenkins',
  String $registry_url = 'artifactory.delivery.puppetlabs.net',
  Optional[String] $token = undef,
  Optional[String] $user_home = undef,
) {
  if $token {
    docker::registry { $registry_url:
      username => 'TOKEN',
      password => $token,
      notify   => Exec['docker credentials tar'],
    }
    exec {'docker credentials tar':
      cwd     => '/root',
      command => '/bin/tar -czf /etc/docker.tar.gz .docker',
      creates => '/etc/docker.tar.gz',
    }
    if $user_home {
      file {
        "${user_home}/.docker":
          ensure => directory,
          owner  => $user
          ;
        "${user_home}/.docker/config.json":
          ensure  => present,
          owner   => $user,
          source  => 'file:///root/.docker/config.json',
          require => Docker::Registry[$registry_url],
      }
    }
  }
}
