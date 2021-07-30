class profile::repo::jenkins_builds (
  Sensitive[String[1]] $sensitive_github_personal_access_token,
  $domain = 'puppetlabs.net',
) {
  profile_metadata::service { $title:
    human_name        => 'Holds automated package builds',
    owner_uid         => 'bradejr',
    team              => re,
    escalation_period => '24/7',
    downtime_impact   => 'No package builds or PE promotions',
  }

  include yum_helpers
  include profile::server::params

  Account::User <| tag == 'jenkins' |>

  ssh::allowgroup { [ 'developers', 'prosvc', 'builder', 'jenkins' ]: }
  sudo::allowgroup { 'builder': }
  Ssh_authorized_key <| tag == 'jenkins' |>

  include profile::nginx

  if $facts['os']['name'] == 'Debian' and $facts['os']['release']['major'] == '7' {
    include apt::backports

    apt::pin { 'nginx-extras':
      packages => 'nginx-extras',
      release  => "${facts['os']['distro']['codename']}-backports",
      priority => '1000',
      require  => Class['apt::backports'],
      before   => Package['nginx-extras'],
    }
  }

  $vhost = "builds.delivery.${domain}"
  $ssl_info = profile::ssl::host_info($vhost)
  nginx::resource::server { $vhost:
    www_root            => '/opt/jenkins-builds',
    autoindex           => 'on',
    ssl                 => true,
    ssl_cert            => $ssl_info['cert'],
    ssl_key             => $ssl_info['key'],
    format_log          => 'logstash_json',
    location_cfg_append => {
      fancyindex            => 'on',
      fancyindex_exact_size => 'off',
    },
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

  file {
    default:
      ensure => directory,
      owner  => 'root',
      group  => 'release',
      mode   => '0755'
      ;
    [ '/var/lib/reprepro', '/etc/reprepro' ]:
      ;
    [ '/opt/jenkins-builds', '/opt/tools', '/opt/logs' ]:
      mode => '0775'
      ;
    # Clean up jenkins-builds directory, because it gets huge!
    '/usr/bin/purge_jenkins_builds.rb':
      ensure => file,
      group  => 'root',
      mode   => '0700',
      source => 'puppet:///modules/profile/delivery/purge_jenkins_builds.rb',
      ;
    '/usr/bin/cleaner_shared_functions.rb':
      ensure => file,
      group  => 'root',
      mode   => '0744',
      source => 'puppet:///modules/profile/delivery/cleaner_shared_functions.rb',
      ;
    '/usr/bin/clean_jenkins_builds.rb':
      ensure => file,
      group  => 'root',
      mode   => '0744',
      source => 'puppet:///modules/profile/delivery/clean_jenkins_builds.rb',
      ;
    '/usr/bin/clean_runtime_builds.rb':
      ensure => file,
      group  => 'root',
      mode   => '0744',
      source => 'puppet:///modules/profile/delivery/clean_runtime_builds.rb',
      ;
    '/usr/bin/jenkins_builds_cleaner.sh':
      ensure  => file,
      group   => 'root',
      mode    => '0700',
      content => epp('profile/delivery/jenkins_builds_cleaner.sh.epp', { 'github_token' => $sensitive_github_personal_access_token }),
      ;
  }

  cron { 'purge_jenkins_builds':
    ensure  => present,
    user    => 'root',
    command => '/usr/bin/purge_jenkins_builds.rb',
    weekday => '*',
    hour    => 9,
    minute  => 0,
  }

  cron { 'jenkins_builds_cleaner' :
    ensure   => present,
    user     => 'root',
    command  => '/usr/bin/jenkins_builds_cleaner.sh',
    monthday => [1, 15],
    weekday  => '*',
    hour     => 8,
    minute   => 0,
  }

  # This is the start of the switchover to aptly!
  class { '::aptly':
    config => {
      'rootDir' => '/opt/tools/aptly',
    },
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
    $partitions = [
      '/opt',
      '/opt/jenkins-builds',
      '/opt/logs',
    ]

    class { '::profile::repo::monitor':
      partitions => $partitions,
    }
  }
}
