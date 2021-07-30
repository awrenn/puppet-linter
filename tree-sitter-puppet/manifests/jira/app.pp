# Manage Jira installation for Puppet Labs
class profile::jira::app {
  profile_metadata::service { $title:
    human_name => 'JIRA Application',
    owner_uid  => 'austin.boyd',
    team       => itops,
    end_users  => ['all@puppet.com'],
    doc_urls   => [
      'https://confluence.puppetlabs.com/display/BTO/JIRA+Service+Document',
    ],
    notes      => @("NOTES"),
      The JIRA database server is combined with the Confluence database server.
      It has group/function `atlassian-db`.
      |-NOTES
  }

  include virtual::users::atlassian
  include jira
  include profile::jira::app::reindex
  include profile::jira::app::fw
  include profile::jira::app::power_db_fields_pro

  if $facts['classification']['stage'] == 'prod' {
    cron { 'jira_db_backup':
      user    => jira,
      command => "pg_dump -h ${jira::dburl} -U ${jira::dbuser} jira > /var/jira/jiradb.sql.bak",
      minute  => '50',
      hour    => '21',
    }
    # Until we transition to puppet.com, use a temporary redirect from
    # tickets.puppet.com to tickets.puppetlabs.com.
    profile::nginx::redirect { 'tickets.puppet.com':
      destination => "https://${jira::app_host}",
      type        => temporary,
      ssl         => true,
      ssl_key     => '/etc/ssl/private/tickets.puppetlabs.com.key',
      ssl_cert    => '/etc/ssl/certs/tickets.puppetlabs.com_combined.crt',
    }

    include ssl
    ssl::cert { 'tickets.puppetlabs.com': }

    class { 'profile::nginx::proxy_ssl':
      hostname             => $jira::app_host,
      proxy_port           => 8080,
      proxy_cache          => true,
      proxy_set_header     => [
        'X-Forwarded-Server $host',
        'X-Forwarded-Host $host',
      ],
      client_set_header    => {
        'Strict-Transport-Security' => 'max-age=31536000',
        'X-Robots-Tag'              => 'noarchive',
      },
      client_max_body_size => '101m',
      canonical_ssl_key    => '/etc/ssl/private/tickets.puppetlabs.com.key',
      canonical_ssl_cert   => '/etc/ssl/certs/tickets.puppetlabs.com_combined.crt',
    }
  }
  else {
    class { 'profile::nginx::proxy_ssl':
      hostname             => $jira::app_host,
      proxy_port           => 8080,
      proxy_cache          => true,
      proxy_set_header     => [
        'X-Forwarded-Server $host',
        'X-Forwarded-Host $host',
      ],
      client_set_header    => {
        'Strict-Transport-Security' => 'max-age=31536000',
        'X-Robots-Tag'              => 'noarchive',
      },
      client_max_body_size => '101m',
    }
  }

  # Purge NGINX cache on JIRA updates
  Class['jira'] ~> Exec['purge NGINX cache']

  Account::User <| title == 'jira' |>
  Account::User <| groups == 'jira' |>
  Group <| title == 'jira' |>

  if $facts['classification']['stage'] == 'test' {
    ssh::allowgroup { 'jira': }
  }

  validate_string($jira::dbuser)
  validate_string($jira::dbpass)
  validate_string($jira::dburl)

  $pgpass = "${jira::dburl}:5432:jira:${jira::dbuser}:${jira::dbpass}\n"

  file { '/home/jira/.pgpass':
    owner   => 'jira',
    group   => '0',
    mode    => '0600',
    content => $pgpass,
  }

  apt::source { 'artifactory':
    location => 'https://artifactory.delivery.puppetlabs.net/artifactory/debian__local_sysops',
    release  => 'jessie',
    repos    => 'main',
  }

  if $profile::server::monitoring {
    include profile::jira::app::monitor
  }
}
