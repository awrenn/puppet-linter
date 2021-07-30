# This code centralizes all management of the database configuration for the
# stated application.  This does not handle server configurration of the
# postgres system itself, but is targeting database creation, password setting,
# iptables access, etc only for the app.
#
class profile::jira::db {
  profile_metadata::service { $title:
    human_name => 'JIRA Database',
    owner_uid  => 'austin.boyd',
    team       => itops,
    end_users  => ['all@puppet.com'],
    doc_urls   => [
      'https://confluence.puppetlabs.com/display/BTO/JIRA+Service+Document',
    ],
    notes      => @("NOTES"),
      The JIRA application server has group `jira`.
      |-NOTES
  }

  include profile::server::params
  $application = 'jira'

  # Use the database password from hiera.  If the database and the jira
  # application are on different hosts, this only works if the data is set in a
  # position in the hierarchy that is common to both nodes.  The target here is
  # stage and group specific, rather than node specific.
  $db_pass = hiera('jira::dbpass')
  $backup_root = '/var/lib/backup/postgres'
  $query = "inventory { facts.classification.group = '${application}' and facts.classification.stage = '${facts['classification']['stage']}' and facts.domain = '${facts['networking']['domain']}' }"
  $sources = puppetdb_query($query).map |$value| { $value['facts']['primary_ip'] }

  if size($sources) < 1 {
    fail("Cannot set up DB for ${application}; no nodes match query '${query}'")
  }

  each($sources) |$source_ip| {
    firewall { "120 allow postgres from ${source_ip} in ${facts['networking']['domain']} ${facts['classification']['stage']} for ${application}":
      proto  => 'tcp',
      action => 'accept',
      dport  => '5432',
      source => $source_ip,
    }
  }

  Postgresql::Server::Pg_hba_rule {
    type        => 'host',
    database    => $application,
    user        => $application,
    auth_method => 'md5',
  }

  each ($sources) |$s| {
    postgresql::server::pg_hba_rule { $s:
      address => "${s}/32",
    }
  }

  postgresql::server::db { $application:
    owner    => $application,
    user     => $application,
    password => postgresql_password($application,$db_pass),
  }

  if $profile::server::params::backups {

    include profile::backup::postgres_backup_dir

    cron { "backup_postgres_${application}":
      command => "/bin/su -l postgres -c '/usr/bin/pg_dump ${application} --create' | nice -n20 gzip --rsyncable > ${backup_root}/${application}.sql.gz",
      user    => 'root',
      hour    => '*',
      minute  => 31,
      require => File[$backup_root],
    }
  }
}
