class profile::getpe {
  profile_metadata::service { $title:
    human_name  => 'GetPE',
    doc_urls    => [
      'https://confluence.puppetlabs.com/display/SRE/GetPE',
    ],
    other_fqdns => [ 'getpe.delivery.puppetlabs.net' ],
    notes       => @("NOTES"),
      Manual steps are required to start the service. See docs.
      |-NOTES
  }

  include profile::nginx

  # Deploy code from Git
  package { 'git': ensure => present, }
  -> vcsrepo { '/var/lib/getpe':
    ensure   => 'present',
    source   => 'git@github.com:puppetlabs/getpe-app.git',
    provider => 'git',
  }

  # Ruby app is run with bundler exec
  $bundler_ver = '1.10.3'
  include rvm

  # Ruby 1.9.3-p484 (default)
  rvm::define::version { 'ruby-1.9.3-p484':
    ensure => present,
    system => 'true',
  }
  rvm::define::gem { "bundler-${bundler_ver}-ruby-1.9.3-p484":
    ensure       => present,
    gem_name     => 'bundler',
    gem_version  => $bundler_ver,
    ruby_version => 'ruby-1.9.3-p484',
  }

  # Nginx proxy
  $keepalive = {
    'keepalive' => '20',
  }

  nginx::resource::upstream { 'getpe_app':
    cfg_prepend => $keepalive,
    members     => {
      'localhost:9292' => {
        server => 'localhost',
        port   => 9292,
      },
    },
  }

  nginx::resource::server { 'getpe.delivery.puppetlabs.net':
    proxy    => 'http://getpe_app',
    ssl      => true,
    ssl_cert => $::profile::ssl::wildcard::certfile,
    ssl_key  => $::profile::ssl::wildcard::keyfile,
  }
}
