# Class: profile::jenkins::usage::ruby::rvm
#
class profile::jenkins::usage::ruby::rvm (
  String $bundler_ver = '1.17.3',
  Boolean $allow_legacy_ruby = true,
) {
  profile_metadata::service { $title:
    human_name => 'Ruby (RVM) build tools for Jenkins',
    team       => 'dio',
    doc_urls   => [
      'https://confluence.puppetlabs.com/display/SRE/Jenkins+Instances',
      'https://plugins.jenkins.io/swarm',
    ],
  }

  include rvm

  $legacy_ruby_versions = [
    '2.0.0-p481',
    '2.1.1',
    '2.1.5',
    '2.1.6',
    '2.1.9',
    '2.2.5',
    '2.3.1',
  ]

  $current_ruby_versions = [
    '2.4.1',
    '2.4.3',
    '2.4.4',
    '2.5.1',
    '2.6.6',
    '2.7.1',
    '2.7.2',
  ]

  if $allow_legacy_ruby {
    $ruby_versions = $legacy_ruby_versions + $current_ruby_versions
  }
  else {
    $ruby_versions = $current_ruby_versions
  }

  $ruby_versions.each |$version| {
    rvm::define::version { "ruby-${version}":
      ensure => present,
      system => 'false',
    }
    rvm::define::gem { "bundler-${bundler_ver}-ruby-${version}":
      ensure       => present,
      gem_name     => 'bundler',
      gem_version  => $bundler_ver,
      ruby_version => "ruby-${version}",
    }
  }
}
