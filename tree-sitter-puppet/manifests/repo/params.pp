##
# This calculates the correct proxy information for yum and apt repos.
#
# To use, include this class and reference its variables.
class profile::repo::params (
  $proxy_host = undef,
  $proxy_port = 3128,
) {
  if $proxy_host == undef {
    $apt_proxy_ensure = 'absent'
  } else {
    $proxy_url        = "http://${proxy_host}:${proxy_port}"
    $apt_proxy_ensure = 'file'
  }
}
