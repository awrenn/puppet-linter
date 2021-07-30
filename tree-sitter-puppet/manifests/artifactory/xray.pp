# Class: profile::artifactory::xray
#
# Class for Artifactory Xray machine.
#
class profile::artifactory::xray (
  String[1] $artifactory_group = 'artifactory',
  String[1] $artifactory_user = 'artifactory',
  String[1] $artifactory_home = '/home/artifactory',
  ) {

  Account::User <| title == $artifactory_user |>
  sudo::allowgroup { 'artifactory': }

  $xray_script_url = 'puppet:///modules/profile/artifactory/xray'

  file { 'xray':
    ensure => file,
    path   => "${artifactory_home}/xray",
    owner  => $artifactory_user,
    group  => $artifactory_group,
    mode   => '0755',
    source => $xray_script_url,
  }
}
