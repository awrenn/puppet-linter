class profile::python::plops {
  include profile::python::packages

  case $facts['os']['family'] {
    'Debian': {
      package { $profile::python::packages::ldap:
        ensure => present,
      }

      python::pip { 'plops':
        ensure       => '0.2.6',
        install_args => "--extra-index-url ${profile::pypi::url}",
        require      => $profile::python::packages::ldap.map |$i| { Package[$i] },
      }
    }
    default: { fail("py-plops not supported on ${facts['os']['family']}") }
  }
}
