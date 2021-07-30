class profile::python (
  $dev        = present,
  $version    = 'system',
  $virtualenv = present,
  $manage_virtualenv_package = true,
  $manage_gunicorn   = false,
  $gunicorn = absent,
){

  include profile::pypi
  include profile::python::packages

  # Some stuff is busticated around virtualenv on SLES 12. It looks like some version numbers
  # on distlib got borked but it seems to work and the spec file that builds it says it is
  # new enough to make virtualenv happy.
  if $facts['os']['name'] == 'SLES' and $facts['os']['release']['major'] == '12' and Integer($facts['os']['release']['major']) >= 4 {
    zypprepo { 'devel_languages_python':
      baseurl     => 'https://download.opensuse.org/repositories/devel:/languages:/python/SLE_12_SP5/',
      enabled     => 1,
      autorefresh => 1,
      descr       => 'Python Modules (SLE_12_SP5)',
      gpgcheck    => 1,
      type        => 'rpm-md',
    }

    package { 'python-distlib':
      ensure  => $virtualenv,
      require => Zypprepo['devel_languages_python'],
      before  => Package['python-virtualenv'],
    }

    # this may have to be installed by hand as dependency resolution may fail
    # hieradata/os/Suse.yaml also turns off managing this package for SUSE clients
    package { 'python-virtualenv':
      ensure  => present,
      require => Zypprepo['devel_languages_python'],
      before  => Class['python'],
    }
  }

  class { 'python':
    dev                       => $dev,
    virtualenv                => $virtualenv,
    manage_virtualenv_package => $manage_virtualenv_package,
    manage_gunicorn           => $manage_gunicorn,
    gunicorn                  => $gunicorn,
    version                   => $version,
    pip                       => 'present',
  }

  # pip 1.1 causes python::pip to think that some pips need updating.
  python::pip { 'pip':
    ensure => '20.3.4', # last version supporting python2
  }

  # newer pip's need the current wheel as the behavior of how its used changed
  python::pip { 'wheel':
    ensure =>  latest,
  }
}
