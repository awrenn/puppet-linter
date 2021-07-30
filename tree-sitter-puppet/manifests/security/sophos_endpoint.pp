# This class installs the sophos endpoint protection agent.
# The installer exe itself contains the registration information. Agent
# updates and products/services are handled through the admin console (i.e. The
# installed version will not match what is reported in the admin console).
#
# Note: Tamper Protection must be disabled in order to uninstall the agent.
#
# The chocolatey package is maintained at https://github.com/puppetlabs/dio-choco-packages
class profile::security::sophos_endpoint(
  Enum[present, absent] $package_ensure = present,
) {
  package { 'sophos-endpoint':
    ensure  => $package_ensure,
    require => Class['profile::chocolatey'],
  }
}
