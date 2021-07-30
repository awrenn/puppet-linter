class profile::pebuildinfo(
  String[1] $github_api_token,
) {
  include epel
  include ruby
  include ruby::dev
  include rvm

  profile_metadata::service { $title:
    human_name => 'PEBuildInfo',
    team       => 're',
    owner_uid  => 'eric.williamson',
    doc_urls   => ['https://github.com/puppetlabs/pebuildinfo'],
  }


  $deploy_directory = '/srv/http'

  file { $deploy_directory:
    ensure => directory,
  }

  exec { 'yum groupinstall Development Tools':
    command => '/usr/bin/yum -y --disableexcludes=all groupinstall "Development Tools"',
    unless  => '/usr/bin/yum grouplist "Development Tools" | /bin/grep "^Installed"',
    timeout => 600,
  }

  package { ['sqlite-devel', 'git']:
    ensure => present,
  }

  vcsrepo { $deploy_directory:
    ensure   => latest,
    provider => git,
    source   => 'git@github.com:puppetlabs/pebuildinfo.git',
    revision => 'main',
    notify   => Exec['install resources'],
    require  => Package['git'],
  }

  file {"${deploy_directory}/config":
    ensure => directory,
  }

  file { "${deploy_directory}/config/.ghpasswd":
    ensure  => file,
    content => $github_api_token,
  }

  # Ruby app is run with bundler exec
  $bundler_ver = '1.16.3'
  rvm::define::version { 'ruby-2.5.1':
    ensure => present,
    system => 'true',
  }

  rvm::define::gem { "bundler-${bundler_ver}-ruby-2.5.1":
    ensure       => present,
    gem_name     => 'bundler',
    gem_version  => $bundler_ver,
    ruby_version => 'ruby-2.5.1',
  }

  exec { 'install resources':
    command     => 'bundle install && bundle exec rake build',
    refreshonly => true,
    cwd         => $deploy_directory,
    path        => ['/usr/local/bin', '/usr/bin', $deploy_directory],
    notify      => Service['pebuildinfo'],
  }

  $unit_file = @("END")
    # /etc/systemd/system/pebuildinfo.service
    [Unit]
    Description=PEBuildInfo service

    [Service]
    Type=simple
    User=root
    Group=root
    ExecStart=/usr/bin/bash -lc '/srv/http/bin/serve'
    Restart=always
    TimeoutSec=10

    [Install]
    WantedBy=multi-user.target
  | END

  file { '/etc/systemd/system/pebuildinfo.service':
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $unit_file,
    notify  => Service['pebuildinfo'],
  }

  service { 'pebuildinfo':
    ensure     => running,
    enable     => true,
    hasrestart => true,
  }

  class { 'postgresql::globals':
    encoding            => 'UTF-8',
    locale              => 'en_US.UTF-8',
    version             => '9.6',
    manage_package_repo => true,
  }

  class { 'postgresql::server':
    listen_addresses => '*',
    require          => Class['postgresql::globals'],
  }

  $db_user = 'pebuildinfo'
  $db_pass = lookup('profile::pebuildinfo::db_pass')

  postgresql::server::pg_hba_rule { 'pebuildinfo_access':
    type        => 'host',
    user        => $db_user,
    database    => 'pebuildinfo',
    address     => '0.0.0.0/0',
    auth_method => 'md5',
  }

  postgresql::server::role { $db_user:
    createdb      => true,
    createrole    => false,
    password_hash => $db_pass,
    login         =>  true,
  }

  postgresql::server::db { 'pebuildinfo':
    owner    => $db_user,
    user     => $db_user,
    password => $db_pass,
  }

  file { "${deploy_directory}/config/.dbpass":
    ensure  => file,
    content => $db_pass,
  }
}
