# A class to remove docker-engine
class profile::docker::purge {

  # Cleanup incase Docker from the Red Hat / CentOS repos had been used
  # This is needed to avoid conflicts with the Docker CE packages.
  # This is also what the offical Docker docs recommend at
  # https://docs.docker.com/install/linux/docker-ce/centos/#uninstall-old-versions
  if $facts['os']['family'] == 'RedHat' {
    $rh_docker_packages = [
      'docker',
      'docker-client',
      'docker-common',
      'docker-engine',
    ]

    $rh_docker_packages.each |String $rh_docker_package| {
      package { "rh_${rh_docker_package}":
        ensure => absent,
        name   => $rh_docker_package,
        notify => Service['docker'],
      }
    }
  }
}
