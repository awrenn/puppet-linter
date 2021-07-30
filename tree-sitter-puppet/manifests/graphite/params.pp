class profile::graphite::params {
  case $facts['os']['family'] {
    'Debian': {
      $relay_web_user = 'www-data'
      $relay_web_group = 'www-data'
    }
    'RedHat': {
      $relay_web_user = 'apache'
      $relay_web_group = 'apache'
    }
    default: {
      $relay_web_user = 'www-data'
      $relay_web_group = 'www-data'
    }
  }
}
