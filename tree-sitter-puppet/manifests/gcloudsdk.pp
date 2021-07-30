class profile::gcloudsdk {
  apt::source { 'gcloud':
    location => 'https://packages.cloud.google.com/apt',
    release  => "cloud-sdk-${::os['distro']['codename']}",
    repos    => 'main',
    key      => '54A647F9048D5688D7DA2ABE6A030B21BA07F4FB',
  }

  package { 'google-cloud-sdk':
    ensure  => latest,
    require => [
      Apt::Source['gcloud'],
      Class['apt::update'],
    ],
  }
}
