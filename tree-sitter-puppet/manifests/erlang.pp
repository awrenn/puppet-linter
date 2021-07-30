class profile::erlang (
  String[1] $package_ensure = 'latest',
) {
  if $facts['os']['family'] == 'Debian' {
    include profile::apt
    apt::source { 'erlang-solutions':
      location => 'http://packages.erlang-solutions.com/debian',
      repos    => 'contrib',
      before   => Package['erlang'],
    }
    apt::key { 'erlang-solutions-gpg-key':
      id     => '0xD208507CA14F4FCA',
      source => 'https://packages.erlang-solutions.com/debian/erlang_solutions.asc',
    }
    $_install_options = undef
  } elsif $facts['os']['family'] == 'RedHat' {
    ## this repo is currently broken, will disable and use epel instead for now.
    yumrepo { 'erlang-solutions':
        baseurl  => 'http://packages.erlang-solutions.com/rpm/centos/$releasever/$basearch',
        enabled  => '0',
        gpgcheck => '1',
        gpgkey   => 'http://packages.erlang-solutions.com/rpm/erlang_solutions.asc',
        descr    => 'Centos $releasever - $basearch - Erlang Solutions',
        before   => Package['erlang'],
    }
    $_install_options = ['--enablerepo=epel-testing-debuginfo,epel-testing-source,epel-testing']
  } else {
    fail("os family ${facts['os']['family']} is not supported in profile::erlang")
  }

  package { 'erlang':
    ensure          => $package_ensure,
    install_options => $_install_options,
  }
}
