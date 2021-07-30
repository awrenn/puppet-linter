# Add apt source for ops-apt.puppet.com
# ops-apt.puppet.com artifacts have been moved to artifactory, but the resource
# name stays the same.
class profile::repos::opsapt (
  Pattern[/\A[0-9A-F]{40}\Z/] $key_fingerprint,
) {
  $code = $facts['os']['distro']['codename']
  $url = 'https://artifactory.delivery.puppetlabs.net/artifactory/debian_sysops_legacy'
  apt::source { 'ops-apt.puppet.com':
    location => $url,
    release  => $code,
    include  => {
      'src' => false,
    },
  }

  apt::key { "ops-apt.puppet.com-sysops-${code}":
    id     => $key_fingerprint,
    source => 'https://artifactory.delivery.puppetlabs.net/artifactory/api/gpg/key/public',
  }
}
