# Reindex JIRA every night
class profile::jira::app::reindex (
  String[1] $username,
  String[1] $password,
) {
  include profile::repo::params
  include puppetlabs::scripts

  file { '/etc/jira.ini':
    ensure => file,
    owner  => 'jira',
    group  => '0',
    mode   => '0400',
  }

  each({
    host     => $jira::app_host,
    user     => $username,
    password => $password,
  }) |$key, $value| {
    ini_setting { "/etc/jira.ini ${key}":
      section => 'JIRA',
      path    => '/etc/jira.ini',
      setting => $key,
      value   => $value,
    }
  }

  cron { 'reindex JIRA':
    command => "${puppetlabs::scripts::base}/jira-reindex >/dev/null",
    user    => 'jira',
    hour    => 22,
    minute  => 30,
  }
}
