class profile::delivery::downloadserver_s3_sync {
  include profile::pypi

  # Originally from https://github.com/danieldreier/generate_directory_indexes
  # Installed from our local pip repository
  # Used to generate Apache-style directory indexes of package repositories
  # prior to uploading to S3
  python::pip { 'generate_directory_indexes':
    ensure       => 'latest',
    install_args => "--extra-index-url ${profile::pypi::url}",
  }

  file { '/usr/local/bin/s3_repo_sync.sh':
    ensure => 'present',
    source => 'puppet:///modules/profile/delivery/s3_repo_sync.sh',
    owner  => 'root',
    mode   => '0700',
  }

}
