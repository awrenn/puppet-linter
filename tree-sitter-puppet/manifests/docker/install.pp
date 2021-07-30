# A class to install docker engine
class profile::docker::install (
  String $ensure = present,
  String $repo_ensure = present,
  String $baseurl = 'https://download.docker.com/linux/centos/7/x86_64/stable/',
  String $gpgkey = 'https://download.docker.com/linux/centos/gpg'
) {

  yumrepo { 'docker':
    ensure   => $repo_ensure,
    descr    => 'repo for docker-engine',
    baseurl  => $baseurl,
    gpgkey   => $gpgkey,
    gpgcheck => true,
  }

  package { 'docker-engine':
    ensure  => $ensure,
    require => Yumrepo['docker'],
  }
}
