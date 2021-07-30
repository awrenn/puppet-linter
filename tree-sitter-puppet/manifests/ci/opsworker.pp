# Class: profile::ci::opsworker
#
# Allows SSH access from the jenkins server
#
class profile::ci::opsworker (
  $include_java = true,
) {
  if $include_java {
    include java
  }

  include profile::python::plops

  # Fabric 2 does not work
  python::pip { 'fabric':
    ensure => '1.14.0',
  }

  Account::User <| title == 'opsjenkins' |>
  Account::User <| title == 'itjenkins' |>
  ssh::allowgroup { 'opsjenkins': }
}
