class profile::repo::nonpe_repos (
  $domain = 'puppetlabs.net',
) {

  include yum_helpers
  include profile::server::params

  [ 'jenkins', 'httpdlogsync' ].each |$group| {
    Account::User <| tag == $group |>
  }

  ssh::allowgroup { [ 'developers', 'prosvc', 'builder', 'jenkins' ]: }
  sudo::allowgroup { 'builder': }
  Ssh_authorized_key <| tag == 'jenkins' |>

  include profile::nginx

  if $facts['os']['name'] == 'Debian' and $facts['os']['release']['major'] == '7' {

    apt::pin { 'nginx-extras':
      packages => 'nginx-extras',
      release  => "${facts['os']['distro']['codename']}-backports",
      priority => '1000',
      require  => Class['apt::backports'],
      before   => Package['nginx-extras'],
    }
  }

  $vhosts = {
    "pl-build-tools.delivery.${domain}"         => '/opt/build-tools',
    "pl-build-tools-staging.delivery.${domain}" => '/opt/build-tools-staging',
    "internal-tools.delivery.${domain}"         => '/opt/internal-tools',
    "test-tools.delivery.${domain}"             => '/opt/test-tools',
  }

  $vhosts.each |String $vhost, String $root| {
    $ssl_info = profile::ssl::host_info($vhost)
    nginx::resource::server { $vhost:
      www_root       => $root,
      autoindex      => 'on',
      listen_options => $vhost ? {
        "pl-build-tools.delivery.${domain}" => 'default_server',
        default                             => undef,
      },
      ssl            => true,
      ssl_cert       => $ssl_info['cert'],
      ssl_key        => $ssl_info['key'],
      format_log     => 'logstash_json',
    }

    if $::profile::server::params::logging {
      include profile::logging::logstashforwarder

      ::logstashforwarder::file { "${vhost}_nginx_access":
        paths  => [
          "/var/log/nginx/${vhost}.access.log",
          "/var/log/nginx/ssl-${vhost}.access.log",
        ],
        fields => {
          'type' => 'nginx_access_json',
        },
      }

      ::logstashforwarder::file { "${vhost}_nginx_error":
        paths  => [
          "/var/log/nginx/${vhost}.error.log",
          "/var/log/nginx/ssl-${vhost}.error.log",
        ],
        fields => {
          'type' => 'nginx_error',
        },
      }
    }
  }


  # RE-2107 Set up build tools repo for debian
  freight::repo { 'pl-build-tools-repo':
    freight_vhost_name       => '',
    freight_docroot          => '/opt/build-tools/debian',
    freight_gpgkey           => '4528B6CD9E61EF26',
    freight_group            => 'release',
    freight_libdir           => '/opt/tools/freight.build-tools',
    freight_manage_docroot   => false,
    freight_manage_libdir    => true,
    freight_manage_vhost     => false,
    freight_manage_ssl_vhost => false,
    freight_redirect         => false,
  }

  freight::repo { 'pl-build-tools-staging-repo':
    freight_vhost_name       => '',
    freight_docroot          => '/opt/build-tools-staging/debian',
    freight_gpgkey           => '4528B6CD9E61EF26',
    freight_group            => 'release',
    freight_libdir           => '/opt/tools/freight.build-tools-staging',
    freight_manage_docroot   => false,
    freight_manage_libdir    => true,
    freight_manage_vhost     => false,
    freight_manage_ssl_vhost => false,
    freight_redirect         => false,
  }

  class { '::aptly':
    user   => 'jenkins',
    config => {
      'architectures' => ['amd64','i386'],
      'rootDir'       => '/opt/tools/aptly',
    },
  }

  $deb_dists = ['wheezy', 'jessie', 'stretch', 'trusty', 'xenial']
  $deb_arches = ['amd64', 'i386']

  $deb_dists.each |String $dist| {
    aptly::repo { "internal-${dist}":
      architectures => $deb_arches,
      component     => 'main',
      distribution  => $dist,
      before        => File['/opt/internal-tools'],
    }
    aptly::repo { "test-${dist}":
      architectures => $deb_arches,
      component     => 'main',
      distribution  => $dist,
      before        => File['/opt/test-tools'],
    }
  }

  file { '/opt/test-tools/debian':
    ensure => link,
    target => '/opt/tools/aptly/public/test',
  }

  file { '/opt/internal-tools/debian':
    ensure => link,
    target => '/opt/tools/aptly/public/internal',
  }

  file {
    default:
      ensure => directory,
      owner  => 'root',
      group  => 'release',
      mode   => '0755'
      ;
    [ '/opt/build-tools', '/opt/build-tools-staging' ]:
      mode => '0775'
      ;
    [ '/opt/internal-tools', '/opt/test-tools' ]:
      mode => '0775'
      ;
    [ '/opt/tools/aptly/internal', '/opt/tools/aptly/internal/staging' ]:
      mode => '0775'
      ;
    [ '/opt/tools/aptly/test', '/opt/tools/aptly/test/staging' ]:
      mode => '0775'
      ;
    [ '/var/lib/reprepro', '/etc/reprepro' ]:
      ;
    [ '/opt/tools', '/opt/logs' ]:
      mode => '0775'
      ;
  }

  package { [ 'rpm', 'devscripts', 'git', 'rake', 'nano', 'tree', 'yum-utils' ]:
    ensure => present,
  }

  # Allow Jenkins to freight stuffs, reprepro stuffs, and chattr stuffs
  sudo::entry{ 'jenkins freight':
    entry => join([
      '%jenkins ALL=(ALL) SETENV: ALL, NOPASSWD:',
      '/usr/bin/createrepo, /usr/bin/freight, /usr/bin/freight-add,',
      '/usr/bin/freight-cache, /usr/bin/freight-init, /usr/bin/reprepro,',
      "/usr/bin/chattr\n",
    ], ' '),
  }

  # httpdlogsync is syncing logs from the burjis, which don't exist.
  cron { 'httpdlogsync':
    ensure =>  absent,
  }

  # Increase the number of open files per process because otherwise the
  # pe_prune cron job will fail and the disk will fill up.
  class { '::ulimit':
    purge => false,
  }

  ulimit::rule {
    default:
      ulimit_domain => '*',
      ulimit_item   => 'nofile'
      ;
    'soft':
      ulimit_type  => 'soft',
      ulimit_value => '5120'
      ;
    'hard':
      ulimit_type  => 'hard',
      ulimit_value => '10240',
  }

  if $::profile::server::params::monitoring {
    $partitions = [ '/opt' ]
    class { '::profile::repo::monitor':
      partitions => $partitions,
    }
  }
}
