# Class: profile::jenkins::usage::shellcheck
#
class profile::jenkins::usage::shellcheck {
  if $facts['os']['family'] == 'Debian' and $facts['os']['release']['major'] >= '8' {
    profile_metadata::service { $title:
      human_name => 'ShellCheck build tools for Jenkins',
      team       => 'dio',
      doc_urls   => [
        'https://confluence.puppetlabs.com/display/SRE/Jenkins+Instances',
        'https://plugins.jenkins.io/swarm',
      ],
    }

    include profile::apt

    package { 'shellcheck':
      ensure  => latest,
    }
  } else {
    notify { "profile::jenkins::usage::shellcheck is not supported on ${facts['os']['family']} release ${facts['os']['release']['major']}": }
  }
}
