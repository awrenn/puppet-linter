# The profile pulls in the Docker container needed for a single node Rancher
# setup. It also takes care of making sure the needed certificate is mounted
# into the container.
#
# @summary Configure a single node Rancher server
#
# @param rancher_version
#   The tag on the rancher/rancher Docker image to pull
#
class profile::rancher::single_node (
  String[1] $rancher_version = 'latest',
){
  case $facts['networking']['domain'] {
    'delivery.puppetlabs.net': {
      include profile::ssl::delivery_wildcard
      $_full_chain_cert = $profile::ssl::delivery_wildcard::combined_file
      $_cert_key = $profile::ssl::delivery_wildcard::keyfile

      Class['profile::ssl::delivery_wildcard'] ~> Docker::Run['rancher']
    }
    'ops.puppetlabs.net': {
      include profile::ssl::ops
      $_full_chain_cert = $profile::ssl::ops::combined_file
      $_cert_key = $profile::ssl::ops::keyfile

      Class['profile::ssl::ops'] ~> Docker::Run['rancher']
    }
    default: {
      fail("${facts['networking']['domain']} is not supported by this profile")
    }
  }

  docker::image { 'rancher/rancher':
    image_tag => 'latest',
  }

  # The Rancher docs say to run the Docker command below. I am including it here
  # for future reference so we know why this "docker::run" resource is configure
  # the way it is.
  #
  # docker run -d --restart=unless-stopped \
  # 	-p 80:80 -p 443:443 \
  # 	-v /<CERT_DIRECTORY>/<FULL_CHAIN.pem>:/etc/rancher/ssl/cert.pem \
  # 	-v /<CERT_DIRECTORY>/<PRIVATE_KEY.pem>:/etc/rancher/ssl/key.pem \
  # 	rancher/rancher:latest \
  #   --no-cacerts
  docker::run { 'rancher':
    systemd_restart           => 'always',
    ports                     => [
      '80:80',
      '443:443',
    ],
    volumes                   => [
      "${_full_chain_cert}:/etc/rancher/ssl/cert.pem",
      "${_cert_key}:/etc/rancher/ssl/key.pem",
    ],
    image                     => "rancher/rancher:${rancher_version}",
    command                   => '--no-cacerts',
    remove_container_on_start => false,
    remove_container_on_stop  => false,
  }

  file {
    default:
      ensure => directory,
      group  => 'root',
      owner  => 'root',
    ;
    '/backup-data':
      mode => '0711',
    ;
    '/backup-data/rancher':
      mode => '0755',
    ;
  }

  profile::rotate_files { '/backup-data/rancher/*':
    keep    => 5,
    require => File['/backup-data/rancher'],
  }
}
