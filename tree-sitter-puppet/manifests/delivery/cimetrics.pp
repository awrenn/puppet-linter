class profile::delivery::cimetrics(
  String $qe_sql_public_ssh_key,
  String $db_host = $facts['networking']['fqdn'],
  String $db_user = 'jenkins_audit',
  String $db_ro_user = 'jenkins_ro',
  String $es_index = 'ci-metrics-v2',
  String $mongodb_user = 'jenkins',
  Boolean $auto_report = false,
){
  profile_metadata::service { $title:
    owner_uid         => 'eric.zounes',
    team              => metrics,
    escalation_period => 'pdx-workhours',
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/Metrics+and+Reporting',
    ],
    notes             => @("NOTES"),
      Run historian?
      |-NOTES
  }

  include profile::server

  # Using hiera lookups to avoid storing secrets in class parameters
  $qe_sql_private_ssh_key = hiera('profile::delivery::cimetrics::qe_sql_private_ssh_key')
  $db_pass = hiera('profile::delivery::cimetrics::db_pass')
  $db_ro_pass = hiera('profile::delivery::cimetrics::db_ro_pass')
  $mongodb_pass = hiera('profile::delivery::cimetrics::mongodb_pass')

  $home_location = '/home/qe-sql'
  $location = "${home_location}/ci-metrics"

  # cron job to push QE metrics data to elasticsearch in the ci-metrics-v2 index
  if $auto_report {
    cron { 'ci-metrics-v2':
      ensure  => present,
      command => "cd ${location}; ./scripts/submit-cimetrics-to-elasticsearch.sh ${es_index} '2 days ago' ${db_host}",
      user    => 'root',
      minute  => 5,
      hour    => '*',
      require => [ Vcsrepo[$location] ],
    }
  }
  Account::User <| title == 'qe-sql' |>

  $deployment_key = "${home_location}/.ssh/id_rsa"
  file { $deployment_key:
    ensure    => file,
    owner     => 'qe-sql',
    group     => 'dio',
    content   => $qe_sql_private_ssh_key,
    mode      => '0600',
    show_diff => false,
  }

  file { "${deployment_key}.pub":
    ensure  => file,
    owner   => 'qe-sql',
    group   => 'dio',
    content => $qe_sql_public_ssh_key,
    mode    => '0644',
  }

  # Deploy code from Git
  vcsrepo { $location:
    ensure   => 'present',
    source   => 'git@github.com:puppetlabs/qe-sql.git',
    provider => 'git',
    identity => $deployment_key,
    user     => 'qe-sql',
    owner    => 'qe-sql',
  }

  $python_packages = [
    'mmh3',
    'pg8000',
    'python-dateutil',
    'pytz',
    'elasticsearch',
  ]

  $python_packages.each |$p| {
    python::pip { $p:
      ensure => 'present',
    }
  }

  class { 'postgresql::globals':
    encoding => 'UTF-8',
    locale   => 'en_US.UTF-8',
    version  => '9.4',
  }

  class { 'postgresql::server':
    listen_addresses => '*',
    require          => Class['postgresql::globals'],
  }

  [$db_user, $db_ro_user].each |$u| {
    postgresql::server::pg_hba_rule { "${u}_access":
      type        => 'host',
      user        => $u,
      database    => 'jenkins_audit',
      address     => '0.0.0.0/0',
      auth_method => 'md5',
    }
  }

  postgresql::server::role { $db_user:
    createdb      => true,
    createrole    => false,
    password_hash => $db_pass,
    login         =>  true,
  }

  postgresql::server::role { $db_ro_user:
    createdb      => false,
    createrole    => false,
    password_hash => $db_ro_pass,
    login         =>  true,
  }

  postgresql::server::database_grant { $db_user:
    role      => $db_ro_user,
    privilege => 'ALL',
    db        => $db_user,
  }

  postgresql::server::db { 'jenkins_audit':
    owner    => $db_user,
    user     => $db_user,
    password => $db_pass,
  }

  mongodb::db { 'jenkinsbfa':
    user          => $mongodb_user,
    password_hash => $mongodb_pass,
  }

  class { '::mongodb::server':
    bind_ip => '0.0.0.0',
  }
}
