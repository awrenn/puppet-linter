class profile::delivery::ci_metrics_v2_push (
  $qe_sql_private_ssh_key,
  $qe_sql_public_ssh_key,
){

  include profile::server

  $home_location = '/home/qe-sql/'
  $location = '/home/qe-sql/ci-metrics'

  # cron job to push QE metrics data to elasticsearch in the ci-metrics-v2 index
  cron { 'ci-metrics-v2':
    ensure  => present,
    command => "cd ${location}; ./scripts/submit-cimetrics-to-elasticsearch.sh ci-metrics-v2 '2 days ago' savitri.delivery.puppetlabs.net",
    user    => 'root',
    minute  => 5,
    hour    => '*',
    require => [ Vcsrepo[$location] ],
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

  python::pip { 'mmh3':
    ensure   => 'present',
  }

  python::pip { 'pg8000':
    ensure   => 'present',
  }

  python::pip { 'python-dateutil':
    ensure   => 'present',
  }

  python::pip { 'pytz':
    ensure   => 'present',
  }

  python::pip { 'elasticsearch':
    ensure   => 'present',
  }
}
