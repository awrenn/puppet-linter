class profile::delivery::composer::packages {
  if $facts['os']['family'] == 'debian' {
    $pkgs = [ 'apt-file', 'gnupg-agent', 'help2man', 'mutt',
              'python3-pip', 'python3-rpm', 'python3-venv',
              'rake', 'zip' ]
    ensure_packages(['progressbar', 'setuptools'], {
      ensure   => present,
      provider => 'pip3',
      require  => [Package['python3-pip'], ],
    })
  } elsif $facts['os']['family'] == 'redhat' {
    # Gnupg2, rubygem-rake is not included because it comes with the rpm-builder module
    $pkgs = ['mutt', 'zip']
  }

  package { $pkgs:
    ensure => installed,
  }
}
