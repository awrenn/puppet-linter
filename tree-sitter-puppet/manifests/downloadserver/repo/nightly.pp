class profile::downloadserver::repo::nightly {
  $nightly_base = '/opt/repository/nightly'
  $projects = ['cfacter', 'facter', 'puppet-agent', 'puppet', 'puppetdb', 'puppetserver']

  if $::profile::server::monitoring {
    include profile::downloadserver::repo::nightly::monitor
  }

  # Base of the docroot
  file { ['/opt/repository', $nightly_base]:
    ensure  => directory,
    owner   => root,
    group   => release,
    mode    => '0775',
    recurse => false,
  }

  # And now the vhost to serve up the nightly repos
  apache::vhost { 'nightlies.puppetlabs.com':
    port     => 80,
    ssl      => false,
    docroot  => $nightly_base,
    template => 'profile/downloadserver/web/vhost.conf.erb',
    require  => File[$nightly_base],
  }

  # And a jenkins user to receive packages
  Account::User <| tag == 'jenkins' |>
  ssh::allowgroup { 'jenkins': }
  Ssh_authorized_key <| tag == 'jenkins' |>

  # We also need to lay down a README and the pubkey for the repositories
  file { 'nightly repo public key':
    ensure => present,
    source => 'puppet:///modules/profile/downloadserver/repo/nightly/07BB6C57',
    path   => "${nightly_base}/07BB6C57",
    owner  => 'root',
    group  => 'release',
    mode   => '0644',
  }

  file { 'nightly repo top level README':
    ensure => present,
    source => 'puppet:///modules/profile/downloadserver/repo/nightly/README',
    path   => "${nightly_base}/README",
    owner  => 'root',
    group  => 'release',
    mode   => '0644',
  }

  # Add symlinks to project-latest inside of the project itself.  Makes beaker happy CPR-275
  $projects.each |String[1] $project| {
    file {"${nightly_base}/${project}/latest":
      ensure => link,
      target => "${nightly_base}/${project}-latest",
    }
  }

  # Clean up nightly directory, because it could get huge!
  # This should remove any nightly builds that have been here more than 14 days
  # The max and min depths here ensure that we operate only on directories
  # under the projects, like puppet/$SHA or facter/$SHA. This won't find
  # puppet-latest (because it is a symlink, not a directory) or any files at
  # top level.
  cron { 'purge_nightly_builds':
    ensure  => present,
    user    => 'root',
    command => "/usr/bin/find ${nightly_base}/ -maxdepth 2 -mindepth 2 -type d -mtime +13 -not -name repo_configs -print0 | /usr/bin/xargs -0 --no-run-if-empty rm -r",
    weekday => 'Monday',
    hour    => 9,
    minute  => 0,
  }

  # INFTOOL-274 - Enable shoving of httpd access logs to logstash
  include profile::logging::logstashforwarder

  ::logstashforwarder::file { 'nightly_foss_repos':
    paths  =>  [ '/var/log/apache2/nightlies.puppetlabs.com*json_access.log'],
    fields =>  { 'type'  => 'foss_downloads' },
  }

  # This is the start of the switchover to aptly!
  class { '::aptly':
    config => {
      'rootDir' => '/opt/tools/aptly',
    },
  }
}
