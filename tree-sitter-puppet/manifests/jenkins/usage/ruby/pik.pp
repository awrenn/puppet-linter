# Class: profile::jenkins::usage::ruby::pik
# This class manages Puppet Labs' fork of Ruby on our Windows spec boxes.
#
class profile::jenkins::usage::ruby::pik {
  $bundler_ver = hiera('profile::jenkins::usage::ruby::bundler_version', '1.15.4')

  package { 'pik':
    ensure   => installed,
    provider => 'chocolatey',
  }

  # Chocolatey installs pik to 'c:\tools\pik'.
  # Manage %PIK_HOME% and its place on %PATH%.
  windows_env { 'set-pik-home':
    ensure    => present,
    variable  => 'PIK_HOME',
    value     => 'c:\tools\pik',
    mergemode => 'clobber',
    require   => Package['pik'],
  }
  windows_env { 'set-pik-path':
    ensure    => present,
    variable  => 'PATH',
    value     => 'c:\tools\pik',
    mergemode => 'insert',
    require   => Package['pik'],
  }

  # Download and manage several releases of 'puppetlabs/puppet-win32-ruby'
  $pik_config = 'c:/tools/pik/config.yml'
  concat { $pik_config:  # default pik config location
    ensure => present,
    order  => 'numeric',
  }
  concat::fragment { 'concat-pik-header':
    target  => $pik_config,
    content => "--- \r\n",
    order   => 1,
  }
  concat::fragment { 'concat-pik-footer':
    target  => $pik_config,
    content => "--- {}\r\n\r\n",
    order   => 1000,
  }

  $ruby_versions = [
    '1.9.3-p484.4',
    '1.9.3-p551.1',
    '2.0.0.3-x64',
    '2.0.0.4-x64',
    '2.1.5.1-x64',
    '2.1.5.1-x86',
    '2.1.5.2-x64',
    '2.1.5.2-x86',
    '2.1.6.0-x64',
    '2.1.6.0-x86',
    '2.1.7.0-x64',
    '2.1.7.0-x86',
    '2.1.9.1-x64',
    '2.1.9.1-x86',
    '2.3.1.1-x64',
    '2.3.1.1-x86',
    '2.4.1.0-x64',
    '2.4.1.0-x86',
  ]

  # The pik file format is as follows
  # Note - Whitespace is important.  Order is VERY VERY important.
  # ---<trailing space>
  # "[ruby-]1.9.3-p484.4":<trailing space>
  #   :path: !ruby/object:Pathname<trailing space>
  #     path: c:/puppet-win32-ruby-1.9.3-p484.4/ruby/bin
  #   :version: |
  #     Ruby 1.9.3-p484.4 (puppetlabs)
  # ...
  # <newline>
  # --- {}
  # <newline>
  # <newline>

  each($ruby_versions) |$index, $version| {
    profile::jenkins::usage::ruby::pik::define { "${version}":
      pik_config       => $pik_config,
      pik_config_order => $index + 2,
    }

    exec { "install-ruby-bundler-${version}":
      path    => "c:/tools/pik;${::path}",
      require => [Package['pik'], Profile::Jenkins::Usage::Ruby::Pik::Define[$version], Concat[$pik_config]],
      command => "cmd.exe /c pik use ${version} && gem install bundler -v ${bundler_ver}",
      unless  => "cmd.exe /c pik use ${version} && gem list bundler -v ${bundler_ver} | find \"bundler\"",
    }
  }
}
