class profile::forgenext::apt_postgres () {
  apt::source { 'forgenext_postgresql_org':
    location => 'http://apt.postgresql.org/pub/repos/apt/',
    release  => "${facts['os']['distro']['codename']}-pgdg",
    repos    => 'main',
    key      => {
      id     => 'B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8',
      server => 'hkps.pool.sks-keyservers.net',
    },
  }
}
