class profile::os::linux::debian::ubuntu {
  apt::source {
    default:
      repos => 'main restricted universe',
    ;
    'main':
      location => 'http://us.archive.ubuntu.com/ubuntu/',
    ;
    'security_updates':
      location => 'http://security.ubuntu.com/ubuntu/',
      release  => "${facts['os']['distro']['codename']}-updates",
    ;
  }

  notify { 'Use Debian':
    message => "Linux distribution ${facts['os']['name']} is barely supported by our control repo.  Please install Debian.",
  }
}

