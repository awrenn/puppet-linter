class profile::aws::cli {
  package { 'awscli':
    ensure   => present,
    provider => 'pip',
  }
}

