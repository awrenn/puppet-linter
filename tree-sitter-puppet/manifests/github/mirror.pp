class profile::github::mirror {

  Account::User <| tag == 'gitmirror' |>
  realize Group['www-data']
  ssh::allowgroup { 'gitmirror': }
  Ssh::Authorized_key <| tag == 'gitmirror-keys' |> # From account::user
  Ssh_authorized_key <| tag == 'gitmirror-keys' |>

  class { 'github::params':
    user         => 'gitmirror',
    group        => 'gitmirror',
    basedir      => '/home/gitmirror',
    wwwroot      => '/var/www/gitmirror',
    vhost_name   => lookup('profile::github::mirror::vhost_name'),
    http_log_dir => lookup('profile::github::mirror::http_log_dir', Data, 'first', nil),
  }

  $mirror_repos = [
    # Open Source Projects
    'puppetlabs/beaker',
    'puppetlabs/facter',
    'puppetlabs/hiera',
    'puppetlabs/puppet',
    'puppetlabs/puppet-server',
    'puppetlabs/puppetdb',
    'puppetlabs/marionette-collective',
    'puppetlabs/puppetlabs_spec_helper',
    'puppetlabs/puppetlabs-strings',
    'puppetlabs/vanagon',
    'puppetlabs/puppet-agent',
    'puppetlabs/puppet-ca-bundle',
    'puppetlabs/cpp-pcp-client',
    'puppetlabs/pxp-agent',

    # Release Engineering Utils
    'puppetlabs/puppet_for_the_win',
    'puppetlabs/packaging',
    'puppetlabs/build-data',
    'puppetlabs/puppet-win32-ruby',

    # Open Source Modules
    'puppetlabs/puppetlabs-stdlib',
    'puppetlabs/puppetlabs-reboot',
    'puppetlabs/puppetlabs-acl',
    'puppetlabs/puppetlabs-havana',
    'puppetlabs/puppetlabs-grizzly',
    'puppetlabs/puppetlabs-auth_conf',
    'puppetlabs/puppetlabs-mysql',
    'puppetlabs/puppetlabs-mongodb',
    'puppetlabs/puppetlabs-postgresql',
    'puppetlabs/puppetlabs-vcsrepo',
    'puppetlabs/puppetlabs-concat',
    'puppetlabs/puppetlabs-apt',
    'puppetlabs/puppetlabs-mcollective',
    'puppetlabs/puppetlabs-nodejs',
    'puppetlabs/puppetlabs-java',
    'puppetlabs/puppetlabs-gce_compute',
    'puppetlabs/puppetlabs-debbuilder',
    'puppetlabs/puppetlabs-git',
    'puppetlabs/puppetlabs-apache',
    'puppetlabs/puppetlabs-puppetdb',
    'puppetlabs/puppetlabs-rabbitmq',
    'puppetlabs/puppetlabs-razor',
    'puppetlabs/puppetlabs-ntp',
    'puppetlabs/puppetlabs-splunk',
    'puppetlabs/puppetlabs-rpmbuilder',
    'puppetlabs/puppetlabs-inifile',
    'puppetlabs/puppetlabs-external_resource',
    'puppetlabs/puppetlabs-corosync',
    'puppetlabs/puppetlabs-ruby',
    'puppetlabs/puppetlabs-stunnel',
    'puppetlabs/puppetlabs-cloud_provisioner',
    'puppetlabs/puppetlabs-lvm',
  ]

  $private_mirror_repos = [
    # Private Forks of Open Source Products
    'puppetlabs/pe-puppet',
    'puppetlabs/pe-facter',
    'puppetlabs/pe-hiera',

    # Private Modules
    ## Ops main Puppet codebase
    'puppetlabs/puppetlabs-modules',
    ## PS or Solutions own this, I think?
    'puppetlabs/puppetlabs-andromeda',
    ## These are modules owned by the PE team
    'puppetlabs/pe_acceptance_tests',
    'puppetlabs/puppetlabs-puppet_enterprise',
    'puppetlabs/puppetlabs-pe_repo',
    'puppetlabs/puppetlabs-request_manager',
    'puppetlabs/puppetlabs-pe_console_prune',
    'puppetlabs/puppetlabs-pe_razor',
    'puppetlabs/puppetlabs-pe_mcollective',
    'puppetlabs/puppetlabs-pe_puppetdb',
    ## Private Forks of Open Source Modules, owned by Module Team
    'puppetlabs/pe-puppetlabs-pe_puppetdb',
    'puppetlabs/pe-puppetlabs-pe_postgresql',
    'puppetlabs/pe-puppetlabs-mysql',
    'puppetlabs/pe-puppetlabs-apache',
    'puppetlabs/classifier',
    'puppetlabs/pe-jvm-puppet-extensions',
    'puppetlabs/ezbake',
    # Ops Utils
    'puppetlabs/diamond-collectors',
    # Release Engineering Utils
    'puppetlabs/homebrew-build-tools',
    'puppetlabs/homebrew-core',
    'puppetlabs/test-suite-vanagon',
    'puppetlabs/pl-build-tools-vanagon',
    'puppetlabs/pl-releng-infra-vanagon',
    'puppetlabs/puppet-client-tools-vanagon',
    'puppetlabs/puppetdb-cli-vanagon',

  ]

  file { '/var/www/gitmirror':
    ensure => directory,
    owner  => 'gitmirror',
    group  => 'www-data',
    mode   => '0750',
  }

  Github::Mirror {
    ensure => present,
  }

  github::mirror { $mirror_repos:
    exportable => true,
  }

  github::mirror { $private_mirror_repos:
    private => true,
  }

  package { 'git':
    ensure => installed,
  }

  file { '/etc/default/gitdaemon':
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/profile/github/gitdaemon.env',
  }

  if $facts['os']['family'] == 'RedHat' {
    package { 'git-daemon':
      ensure => installed,
      before => Service['git.socket'],
    }

    service { 'git.socket':
      ensure     => 'running',
      enable     => true,
      hasrestart => true,
    }

  } elsif $facts['os']['family'] == 'Debian' {
    file { '/etc/init.d/gitdaemon':
      owner  => 'root',
      group  => 'root',
      mode   => '0770',
      source => 'puppet:///modules/profile/github/gitdaemon.init',
    }

    service { 'gitdaemon':
      ensure     => 'running',
      enable     =>  true,
      hasrestart =>  true,
      require    =>  [
        File['/etc/init.d/gitdaemon'],
        File['/etc/default/gitdaemon'],
        File['/var/www/gitmirror'],
        Package['git'],
      ],
    }
  }

  file { '/home/gitmirror/.ssh/id_rsa':
    owner     => 'gitmirror',
    group     => 'gitmirror',
    mode      => '0600',
    content   => lookup('profile::github::mirror::gitmirror_ssh_key'),
    show_diff => false,
  }
}
