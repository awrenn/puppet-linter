# Class: profile::artifactory::monitoring
#
# Configuring monitoring for HAProxy on Artifactory.
#
class profile::artifactory::monitoring(
  String[1] $artifactory_cname = 'artifactory.delivery.puppetlabs.net',
) inherits profile::monitoring::icinga2::common {

  @@icinga2::object::service { "${artifactory_cname}_http":
    check_command => 'http',
    vars          => {
      http_address => $artifactory_cname,
      http_ssl     => true,
      escalate     => true,
    },
    tag           => ['singleton'],
  }
}
