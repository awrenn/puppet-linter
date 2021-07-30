# This profile configures rsyncd on the burjis.
class profile::downloadserver::rsync {

  user { 'rsync':
    ensure         => present,
    managehome     => true,
    gid            => 'release',
    home           => '/home/rsync',
    purge_ssh_keys => true,
  }

  ssh_authorized_key { 'weth-rsync-ssh':
    ensure => present,
    user   => 'rsync',
    type   => 'ssh-rsa',
    key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC+uRQjtqoBGcVIi2dqPeR2IDF1apvtFPdrjtHgo8GEQrhBdy6Fs447a/qgwV2/x7cbvW4eX4Fk/LN9uij9JhyAS8TeInSiF6nOeeTTmRiGDzEX683k08h1JiIqBDeNjZfqZq983KRBWeKj/YOuWSi7ukDpLXTIht7TatLtnSbLjtBSLLlORVNelsOi0HgbyKfL0/1THL93MxBatl1u+QfnNidho1ZfDlePJ1lFEDM+EWaqqc/U0E5VMiuoQYns3U0HbfaORhvaU825d5s9LBzrXOZq2WshxxV/VV/Vnjlh9H8pUqqIez0BhRLqGR/dRUwFQoIUgdnQ8psAhF6DqBKR',
  }

  firewall { '200 allow rsyncd':
    dport  => ['873'],
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '200 allow rsyncd v6':
    dport    => ['873'],
    proto    => 'tcp',
    action   => 'accept',
    provider => 'ip6tables',
  }

  class { '::rsync':
    manage_package => false,
  }

  class { '::rsync::server':
    use_xinetd => false,
    uid        => 'nobody',
    gid        => 'nogroup',
  }

  file { ['/opt/repository', '/opt/repository/apt', '/opt/repository/yum', '/opt/repository/downloads']:
    ensure => directory,
    owner  => 'rsync',
    group  => 'release',
  }

  ::rsync::server::module { 'packages':
    path            => '/opt/repository',
    comment         => 'Puppet Labs Package Repository',
    max_connections => '60',
    incoming_chmod  => false,
    outgoing_chmod  => false,
    uid             => 'nobody',
    gid             => 'nogroup',
    exclude         => ['Rakefile', 'tasks/***', 'incoming/***',
                        'apt/enterprise/***', 'yum/fedora/f15/***',
                        'yum/fedora/f16/***', 'yum/enterprise/***'],
  }
}
