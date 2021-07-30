# Class: profile::jenkins::usage::qetools
#
class profile::jenkins::usage::qetools {
  profile_metadata::service { $title:
    human_name => 'QE (aka DIO) build tools for Jenkins',
    team       => 'dio',
    doc_urls   => [
      'https://confluence.puppetlabs.com/display/SRE/Jenkins+Instances',
      'https://plugins.jenkins.io/swarm',
    ],
  }

  # QENG-3685 git-sweep
  python::pip { 'git-sweep':
    ensure   => '0.1.1',
  }
}
