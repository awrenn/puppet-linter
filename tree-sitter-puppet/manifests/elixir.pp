class profile::elixir {
  include git
  include profile::erlang

  # elixir packaging for RedHat/CentOS is limited, so we only install elixir
  # on Debian. This isn't a big problem because it's easy to package elixir
  # into elixir applications and run it on erlang directly.
  if $facts['os']['family'] == 'Debian' {
    include profile::apt
    package { 'elixir':
      ensure  => latest,
    }
  }
}
