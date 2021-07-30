# Install the requests package globally
class profile::python::requests {
  case [ $facts['os']['family'], "${facts['os']['release']['major']}" ] {
    ['Solaris', Any], ['Debian', '7']: {
      # It's easier to install requests via pip on Solaris, and the version in
      # Debian 7's system repos is astonishingly old.
      python::pip { 'requests': ensure => latest }
    }
    default: {
      # Recent pip versions of requests vendor a version of urllib3 which
      # conflicts with the requirements of some applications, including
      # critical components of OpenStack, so we use the system package version
      # instead, which doesn't have that issue.
      package { 'python-requests': ensure => latest }
    }
  }
}
