class profile::release::webserver {
  include profile::nginx

  file { '/opt/release':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/opt/release/enterprise':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/opt/release/enterprise/repos.html':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/profile/release/enterprise_repos.html',
  }

  file { '/opt/release/enterprise/index.html':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/profile/release/enterprise.html',
  }

  $vhost = 'release-web-prod-1.delivery.puppetlabs.net'
  $ssl_info = profile::ssl::host_info($vhost)
  nginx::resource::server { 'saturn-redirects':
    ensure        => present,
    listen_port   => 80,
    www_root      => '/opt/release/enterprise',
    ssl           => true,
    ssl_cert      => $ssl_info['cert'],
    ssl_key       => $ssl_info['key'],
    server_name   => [$vhost, 'saturn.*', 'neptune.*', 'enterprise.*', 'freight.*', 'apt-dev.*', 'pkgs.*', 'pebuilds.*', 'perepos.*', 'webstats.*', 'pe-dev.*'],
    rewrite_rules => [
      '^/build-tools/(el|sles|fedora|aix)/([.0-9]+)/(.*)$ https://artifactory.delivery.puppetlabs.net/artifactory/rpm_enterprise__local/build-tools/repos/$1-$2-$3 last',
      '^/build-tools/debian/CumulusLinux(.*)$ https://artifactory.delivery.puppetlabs.net/artifactory/debian_enterprise__local/build-tools/repos/cumulus$1 last',
      '^/misc(.*)$ https://artifactory.delivery.puppetlabs.net/artifactory/generic_enterprise__local/misc$1 last',
      '^/archives(.*)$ https://artifactory.delivery.puppetlabs.net/artifactory/generic_enterprise__local/archives$1 last',
      '^/(.*)/ci-ready(.*)$ https://artifactory.delivery.puppetlabs.net/artifactory/generic_enterprise__local/$1/ci-ready$2 last',
      '^/(.*)/(feature|release)/repos/(el|sles|redhatfips)(-.*)$ https://artifactory.delivery.puppetlabs.net/artifactory/rpm_enterprise__local/$1/$2/$3$4 last',
      '^/(.*)/repos/(el|sles|redhatfips)(-.*)$ https://artifactory.delivery.puppetlabs.net/artifactory/rpm_enterprise__local/$1/repos/$2$3 last',
      '^/(.*)/bionic(.*)$ $scheme://$host/$1/ubuntu-18.04$2',
      '^/(.*)/xenial(.*)$ $scheme://$host/$1/ubuntu-16.04$2',
      '^/(.*)/(feature|release)/repos/(ubuntu.*)$ https://artifactory.delivery.puppetlabs.net/artifactory/debian_enterprise__local/$1/$2/$3 last',
      '^/(.*)/repos/(ubuntu.*)$ https://artifactory.delivery.puppetlabs.net/artifactory/debian_enterprise__local/$1/repos/$2 last',
      '^/(.*)/(feature|release)/repos(.*)$ $scheme://$host/repos.html last',
      '^/(.*)/repos(.*)$ $scheme://$host/repos.html last',
    ],
  }

  $pe_releases_ssl_info = profile::ssl::host_info('pe-releases.delivery.puppetlabs.net')
  nginx::resource::server { 'pe-releases-redirects':
    ensure      => present,
    listen_port => 80,
    www_root    => '/opt/release/enterprise',
    ssl         => true,
    ssl_cert    => $pe_releases_ssl_info['cert'],
    ssl_key     => $pe_releases_ssl_info['key'],
    server_name => ['pe-releases.*'],
    raw_append  => 'return 301 https://artifactory.delivery.puppetlabs.net/artifactory/generic_enterprise__local/archives/releases$request_uri;',
  }
}
