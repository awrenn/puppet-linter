class profile::graphite::db (
  String $private_key = '',
  String $public_key = '',
) {
  profile_metadata::service { $title:
    human_name        => 'Graphite PostgreSQL database',
    team              => dio,
    end_users         => [
      'infrastructure-user@puppet.com',
      'discuss-sre@puppet.com',
    ],
    escalation_period => '24x7',
    downtime_impact   => "Users can't access metrics.",
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/Graphite+Service+Page',
    ],
  }

  include profile::postgresql::install
  include profile::postgresql::configuration
  include profile::postgresql::pg_hba_rules
  include profile::postgresql::create_role
  include profile::postgresql::create_database
  include profile::postgresql::backup_db

  # Replication items
  realize Group['postgresreplication']
  ssh::allowgroup {'postgresreplication': }
  user { 'postgres':
    groups  => ['postgres','postgresreplication'],
    require => Group['postgresreplication'],
  }

  # Add SSH Keys Dir
  file { '/var/lib/postgresql/.ssh':
    ensure => 'directory',
    owner  => 'postgres',
    mode   => '0700',
  }

  file { '/var/lib/postgresql/.ssh/id_rsa.pub':
    ensure  => 'present',
    content => $public_key,
    owner   => 'postgres',
    mode    => '0600',
    require => [User['postgres'], File['/var/lib/postgresql/.ssh']],
  }
  file { '/var/lib/postgresql/.ssh/id_rsa':
    ensure  => 'present',
    content => $private_key,
    owner   => 'postgres',
    mode    => '0600',
    require => [User['postgres'], File['/var/lib/postgresql/.ssh']],
  }
}
