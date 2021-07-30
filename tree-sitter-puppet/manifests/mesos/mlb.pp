# Class: profile::mesos::mlb
#
class profile::mesos::mlb(
  String $haproxy_cert,
  String $haproxy_group = 'external',
  String $marathon = 'marathon.mesos',
  String $revision = 'v1.11.3',
){

  include git
  include ssl

  meta_motd::register { 'Marathon LB (profile::mesos::mlb)': }

  package { [ 'libffi-dev', 'python3-dev' ]:
    ensure => latest,
  }

  vcsrepo { '/opt/marathon-lb':
    ensure   => present,
    provider => 'git',
    source   => 'https://github.com/mesosphere/marathon-lb.git',
    revision => $revision,
  }

  file { '/marathon-lb':
    ensure  => link,
    target  => '/opt/marathon-lb',
    require => Vcsrepo['/opt/marathon-lb'],
  }

  python::virtualenv { '/opt/marathon-lb-python':
    version    => '3',
    virtualenv => true,
  }

  python::requirements { '/opt/marathon-lb/requirements.txt':
    virtualenv => '/opt/marathon-lb-python',
    require    => Vcsrepo['/opt/marathon-lb'],
  }

  $cert_path = "${ssl::cert_dir}/${haproxy_cert}.crt"
  ssl::cert::haproxy { $haproxy_cert:
    path => $cert_path,
  }

  cron {'marathon-lb':
    user        => 'root',
    command     => "/opt/marathon-lb/marathon_lb.py -m http://${marathon}:8080 --group ${haproxy_group} --ssl-certs ${cert_path}",
    environment => 'PATH=/opt/marathon-lb-python/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
  }

  # only want the package since marathon-lb manages the haproxy config,
  # so not using haproxy
  if $facts['os']['name'] == 'Debian' and $facts['os']['release']['major'] == '8' {
    include apt::backports

    # needed to get haproxy 1.6
    apt::pin { 'haproxy-backports':
      packages => 'haproxy libssl1.0.0',
      release  => "${lsbdistcodename}-backports",
      priority => '1000',
      require  => Class['apt::backports'],
    }
  }

  package { 'haproxy':
    ensure  => present,
  }

  profile_metadata::service { $title:
    human_name      => 'marathon-lb',
    team            => 'dio',
    end_users       => [
      'team-development-infrastructure-and-operations@puppet.com',
      'infrastructure-users@puppetlabs.com',
    ],
    doc_urls        => [
      'https://confluence.puppetlabs.com/display/SRE/Mesos',
      'https://github.com/puppetlabs/cinext-docs/tree/master/infrastructure#marathon-lb',
    ],
    downtime_impact => @(END),
      Marathon-lb configures haproxy based on labels on marathon applications. Vmpooler,
      ABS and CITH are examples of applications we commonly interact with through marathon-lb.
      If the service is down then access to APIs served through this service will be unavailable.
      | END
  }
}
