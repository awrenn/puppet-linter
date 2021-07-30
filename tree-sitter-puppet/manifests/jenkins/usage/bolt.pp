class profile::jenkins::usage::bolt {
  package { 'puppet-bolt':
    ensure  => latest,
  }
}
