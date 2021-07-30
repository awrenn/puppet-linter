#
class profile::jira_reports (
  $jira_username,
  $jira_password,
  $backend_port = '8888',
  $jira_host    = 'https://tickets.puppetlabs.com',
) {
  include profile::server
  include profile::nginx
  include profile::bizops

  nginx::resource::map { 'connection_upgrade':
    ensure   => present,
    default  => 'upgrade',
    string   => '$http_host',
    mappings => {"''" => 'close'},
  }

  $backend_host = 'jira_reports_backend'
  nginx::resource::upstream { $backend_host:
    members => {
      "localhost:${backend_port}" => {
        server => 'localhost',
        port   => scanf($backend_port, '%i')[0],
      },
    },
  }

  $frontend_dir = '/opt/bizops/jira-reports-frontend'
  nginx::resource::server { $facts['networking']['fqdn']:
    ensure      => present,
    listen_port => 80,
    server_name => [$facts['networking']['fqdn']],
    www_root    => $frontend_dir,
    index_files => ['index.html', 'index.htm'],
    try_files   => ['$uri $uri/ /index.html?/$request_uri'],
    add_header  => {'Content-Security-Policy' => "\"default-src 'none'; script-src 'self'; font-src 'self'; connect-src 'self' ${facts['networking']['fqdn']}; img-src 'self'; style-src 'self'; media-src 'self'\""}, # lint:ignore:140chars
  }

  nginx::resource::location { '/api/':
    ensure           => present,
    server           => $facts['networking']['fqdn'],
    proxy            => "http://${backend_host}",
    proxy_set_header => ['Upgrade $http_upgrade', 'Connection $connection_upgrade'],
  }

  package { 'jira-reports-frontend':
    ensure => latest,
  }

  package { 'jira-reports-backend':
    ensure => latest,
  }

  file {'/opt/bizops/jira-reports-backend/jira-reports-backend.conf':
    ensure  => present,
    content => template('profile/jira_reports/jira-reports-backend.conf.erb'),
    links   => follow,
    require => Package['jira-reports-backend'],
  }

  service { 'jira-reports-backend':
    ensure    => running,
    subscribe => File['/opt/bizops/jira-reports-backend/jira-reports-backend.conf'],
  }
}
