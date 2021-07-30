class profile::ci::bizops {
  include profile::jenkins::usage::nodejs
  include profile::elixir

  file {'/opt/bizops':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => Class['::jenkins'],
  }
}
