class profile::forgenext::anubis {
  Account::User <| title == 'forgeapi' |>

  # anubis requires curl headers to build
  package{ 'libcurl4-openssl-dev':
    ensure => latest,
  }

  package { 'rake':
    ensure   => present,
    provider => gem,
  }

  file { '/opt/anubis':
    ensure => directory,
    owner  => 'forgeapi',
    group  => 'forgeapi',
  }

  # Add place to deploy anubis to.
  file { '/opt/anubis/build':
    ensure  => directory,
    owner   => 'forgeapi',
    group   => 'forgeapi',
    require => File['/opt/anubis'],
  }

  # Set up anubis bundles symlink
  file { '/opt/anubis/bundles':
    ensure  => link,
    target  => '/opt/anubis/build/bundles',
    owner   => 'forgeapi',
    group   => 'forgeapi',
    require => File['/opt/anubis/build'],
  }
}
