class profile::kerminator {
  include build
  include profile::server
  include selinux

  # Needed for poking at the brain now and again.
  ensure_packages(['jq'], {'ensure' => 'latest'})

  ssh::allowgroup   { 'chatops': }
  realize(Group['chatops'])
  Account::User <| groups == 'chatops' |>
  sudo::allowgroup { [ 'chatops' ]: }

  user { 'kerminator':
    ensure     => present,
    home       => '/home/kerminator',
    managehome => true,
    system     => true,
  }

  file { '/home/kerminator/':
    ensure => directory,
    owner  => 'kerminator',
    group  => 'kerminator',
  }

  file { '/home/kerminator/.ssh':
    ensure => directory,
    owner  => 'kerminator',
    group  => 'kerminator',
  }

  # kerminator github deployment key
  file { '/home/kerminator/.ssh/id_dsa':
    ensure => present,
    owner  => 'kerminator',
    group  => 'kerminator',
    mode   => '0600',
    source => 'puppet:///modules/profile/kerminator/kerminator.deploy_key',
  }

  # this is a dep for the cowsay command set
  package { 'cowsay':
    ensure => present,
  }

  $nsfw_cows = ['bong', 'sodomized', 'telebears']
  $nsfw_cows.each |$cow| {
    file { "${cow}.cow":
      ensure  => absent,
      owner   => 'kerminator',
      group   => 'kerminator',
      mode    => '0644',
      path    => "/usr/share/cowsay/${cow}.cow",
      require => Package['cowsay'],
    }
  }

  vcsrepo { 'kerminator':
    ensure   => latest,
    provider => git,
    path     => '/var/lib/kerminator',
    source   => 'git@github.com:puppetlabs/kerminator.git',
    user     => 'kerminator',
    owner    => 'kerminator',
    identity => '/home/kerminator/.ssh/id_dsa',
    require  => [ User['kerminator'], File['/home/kerminator/.ssh'] ],
  }

  exec { 'ownership of kerminator':
    unless  => '/bin/find /var/lib/kerminator ! -user kerminator > /dev/null',
    cwd     => '/var/lib/kerminator',
    path    => '/usr/bin:/usr/local/bin:/usr/sbin:/usr/local/sbin:/bin:/sbin',
    command => 'chown -R kerminator:kerminator /var/lib/kerminator',
    require => [Vcsrepo['kerminator'], User['kerminator']],
  }

  file { '/var/log/kerminator/kerminator.log':
    ensure  => present,
    owner   => 'kerminator',
    group   => 'kerminator',
    mode    => '0644',
    require => Vcsrepo['kerminator'],
  }

  file { '/etc/kerminator':
    ensure  => directory,
    mode    => '0755',
    owner   => 'kerminator',
    group   => 'kerminator',
    require => Vcsrepo['kerminator'],
  }

  file { '/etc/kerminator/environment':
    ensure                  => 'link',
    target                  => '/var/lib/kerminator/environment',
    require                 => Vcsrepo['kerminator'],
    notify                  => Service['kerminator'],
    selinux_ignore_defaults => true,
  }

  file { '/etc/kerminator/secrets':
    owner   => 'kerminator',
    group   => 'kerminator',
    mode    => '0600',
    notify  => Service['kerminator'],
    require => Vcsrepo['kerminator'],
  }

  file { '/var/log/kerminator':
    ensure => directory,
    owner  => 'kerminator',
    group  => 'kerminator',
    mode   => '0755',
  }

  file { 'kerminator-logrotate':
    ensure  => file,
    force   => true,
    path    => '/etc/logrotate.d/kerminator',
    source  => '/var/lib/kerminator/contrib/kerminator.logrotate',
    require => Vcsrepo['kerminator'],
  }

  sudo::entry { 'kerminator':
    entry   => [
      'kerminator ALL=(ALL) NOPASSWD:',
      '/usr/bin/git,',
      '/usr/local/bin/puppet,',
      '/bin/systemctl start kerminator.service,',
      '/bin/systemctl status kerminator.service,',
      '/bin/systemctl stop kerminator.service,',
      '/bin/systemctl restart kerminator.service,',
      '/bin/systemctl daemon-reload,',
      '/bin/install,',
      '/bin/chown,',
      '/bin/cp',
      ].join(' '),
    require => Vcsrepo['kerminator'],
    before  => Exec['install-kerminator'],
  }

  exec { 'install-kerminator':
    command     => 'make install-production',
    user        => 'kerminator',
    unless      => 'test -L /etc/kerminator/environment',
    logoutput   => on_failure,
    cwd         => '/var/lib/kerminator',
    path        => '/usr/bin:/usr/local/bin:/usr/sbin:/usr/local/sbin:/bin:/sbin',
    environment => ['HOME=/var/lib/kerminator'],
    require     => [ Vcsrepo['kerminator'], Package['nodejs'] ],
  }

  service { 'kerminator':
    ensure    => running,
    enable    => true,
    hasstatus => true,
    require   => [ File['/var/log/kerminator/kerminator.log'], File['kerminator.service'], Vcsrepo['kerminator'], Exec['install-kerminator'] ],
    subscribe => [ File['kerminator.service'] ],
  }

  file { 'kerminator.service':
    ensure  => present,
    path    => '/etc/systemd/system/kerminator.service',
    source  => '/var/lib/kerminator/contrib/kerminator.service',
    require => Vcsrepo['kerminator'],
    notify  => Exec['puppetlabs-modules systemctl daemon-reload'],
  }

  file { '/etc/cron.hourly/1brain_dump.sh':
    ensure                  => present,
    source                  => '/var/lib/kerminator/contrib/backup-file-brain.sh',
    selinux_ignore_defaults => true,
    mode                    => '0755',
    owner                   => 'root',
    group                   => 'root',
    require                 => Vcsrepo['kerminator'],
  }

  # Adding a job to restart kerminator prior to BFS coming online as it often
  # is hung. This is a problem with the hubot adapter and hopefully won't be
  # needed once we move away from hipchat. :hope:
  cron { 'restart-kerminator':
    ensure => absent,
  }

  # Install nodejs on centos 7 a...special way
  exec { 'install_nodejs_yum_repo':
    path    => '/usr/bin:/usr/local/bin:/usr/sbin:/usr/local/sbin:/bin:/sbin',
    command => 'curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -',
    unless  => 'rpm -q nodesource-release',
  }

  package { 'nodejs':
    ensure  => present,
    require => Exec['install_nodejs_yum_repo'],
  }

  profile_metadata::service { $title:
    human_name => 'kerminator',
    team       => 'RE',
    owner_uid  => 'stahnma',
    doc_urls   => ['https://github.com/puppetlabs/kerminator'],
  }
}
