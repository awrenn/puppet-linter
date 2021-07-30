# Manage confluence installation for Puppet Labs
class profile::confluence::app {
  profile_metadata::service { $title:
    human_name => 'Confluence Application',
    owner_uid  => 'austin.boyd',
    team       => itops,
    end_users  => ['all@puppet.com'],
    doc_urls   => [
      'https://confluence.puppetlabs.com/display/BTO/Confluence+Service+Document',
    ],
    notes      => @("NOTES"),
      The Confluence database server is combined with the JIRA database server.
      It has group/function `atlassian-db`.
      |-NOTES
  }

  include virtual::users::atlassian
  include confluence

  if $facts['classification']['stage'] == 'prod' {
    cron { 'confluence_db_backup':
      user    => confluence,
      command => "pg_dump -h ${confluence::dburl} -U ${confluence::dbuser} confluence > /var/confluence/confluencedb.sql.bak",
      minute  => '50',
      hour    => '21',
    }
  }

  if $facts['classification']['stage'] == 'prod' {
    # Until we transition to puppet.com, use a temporary redirect from
    # confluence.puppet.com to confluence.puppetlabs.com.
    #
    # This creates a redirect even on test nodes, but it doesn't matter because
    # confluence.puppet.com DNS only points to production.
    profile::nginx::redirect { 'confluence.puppet.com':
      destination => "https://${confluence::app_host}",
      type        => temporary,
      ssl         => true,
      ssl_key     => '/etc/ssl/private/confluence.puppetlabs.com.key',
      ssl_cert    => '/etc/ssl/certs/confluence.puppetlabs.com_combined.crt',
    }

    include ssl

    ssl::cert { 'confluence.puppetlabs.com': }

    class { 'profile::nginx::proxy_ssl':
      hostname             => $confluence::app_host,
      proxy_port           => 8090,
      proxy_cache          => true,
      proxy_set_header     => [
        'X-Forwarded-Server $host',
        'X-Forwarded-Host $host',
      ],
      client_set_header    => {
        'Strict-Transport-Security' => 'max-age=31536000',
      },
      client_max_body_size => '101m',
      canonical_ssl_key    => '/etc/ssl/private/confluence.puppetlabs.com.key',
      canonical_ssl_cert   => '/etc/ssl/certs/confluence.puppetlabs.com_combined.crt',
    }
  }
  else {
    class { 'profile::nginx::proxy_ssl':
      hostname             => $confluence::app_host,
      proxy_port           => 8090,
      proxy_cache          => true,
      client_max_body_size => '101m',
    }
  }

  # Purge NGINX cache on JIRA updates
  Class['confluence'] ~> Exec['purge NGINX cache']

  #redirect forgot password link to jira
  nginx::resource::location { '/forgotuserpassword.action':
    server              => $confluence::app_host,
    ssl_only            => true,
    location_custom_cfg => {
      'return 301' => 'https://tickets.puppetlabs.com/secure/ForgotLoginDetails.jspa',
    },
  }

  Account::User <| title == 'confluence' |>
  Group <| title == 'confluence' |>

  validate_string($confluence::dbuser)
  validate_string($confluence::dbpass)
  $db_host = split($confluence::dburl, '/')[2]

  file { '/home/confluence/.pgpass':
    owner   => 'confluence',
    group   => '0',
    mode    => '0400',
    content => "${db_host}:confluence:${confluence::dbuser}:${confluence::dbpass}",
  }

  apt::source { 'artifactory':
    location => 'https://artifactory.delivery.puppetlabs.net/artifactory/debian__local_sysops',
    release  => 'jessie',
    repos    => 'main',
  }

  if $profile::server::monitoring {
    include profile::confluence::app::metrics
  }

  if $profile::server::monitoring {
    include profile::confluence::app::monitor
  }
}
