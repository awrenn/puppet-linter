class profile::python::packages (
  $pip_ensure = latest,
  $setuptools_version = '44.1.0', # last python2 version
){
  case $facts['os']['family'] {
    'Debian': { $ldap = ['libldap2-dev', 'libsasl2-dev', 'libssl-dev'] }
  }

  python::pip {
    default:
      ensure => $pip_ensure,
    ;
    'setuptools':
      ensure => $setuptools_version,
    ;
    'pyyaml':
      require => Python::Pip['setuptools'],
    ;
  }

}

