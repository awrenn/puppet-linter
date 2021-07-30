# This profile is responsible for setting up a node to be the self hosted runner
# for one or more GitHub repositories.
#
class profile::ghactions::runner (
  Array[String] $repos,
  Sensitive[String[1]] $ghactions_private_key = Sensitive(lookup('infracore_ghactions_runner_private_key')),
  Stdlib::HTTPSUrl $runner_package = 'https://githubassets.azureedge.net/runners/2.160.2/actions-runner-linux-x64-2.160.2.tar.gz',
  String[5] $ruby_version = '2.6.3',
  Boolean $docker_access = false,
  String[1] $redhat_git_package = 'rh-git218',
  String[1] $redhat_git_lfs_package = 'rh-git218-git-lfs',
  Boolean $disable_flag = false,
) {
  profile_metadata::service { $title:
    human_name => 'Self-hosted GitHub Actions runner',
    owner_uid  => 'gene.liverman',
    doc_urls   => ['https://confluence.puppetlabs.com/display/SRE/Deploy+and+Configure+GitHub+Actions+Runner'],
  }

  validate_re($ruby_version, '^\d\.\d+\.\d+$', 'The ruby_version parameter must be in x.y.z format such as 2.6.3')

  $_svc_account = 'ghactions'
  $_ruby_version_parts = split($ruby_version, Regexp['[.]'])
  $_ruby_minor_version = "${_ruby_version_parts[0]}.${_ruby_version_parts[1]}"
  $_gh_runner_path_base = [
    "/home/${_svc_account}/.gem/ruby/${_ruby_minor_version}.0/bin",
    "/home/${_svc_account}/.rvm/gems/ruby-${ruby_version}/bin",
    "/home/${_svc_account}/.rvm/gems/ruby-${ruby_version}@global/bin",
    "/home/${_svc_account}/.rvm/rubies/ruby-${ruby_version}/bin",
    '/usr/local/bin',
    '/usr/bin',
    '/bin',
    '/opt/puppetlabs/bin',
    "/home/${_svc_account}/.rvm/bin",
  ]

  Package <| tag == 'ghactions-git' |> ~> Service <| tag == 'ghactions-service' |>

  case $facts['os']['family'] {
    'Debian': {
      $_git_scl_path = udef
      $_gh_runner_path = join($_gh_runner_path_base, ':')

      package { 'git':
        ensure => present,
        tag    => ['ghactions-git'],
      }
    }
    'RedHat':{
      include profile::os::linux::redhat::scl_repos

      $_git_scl_path = "/opt/rh/${redhat_git_package}/enable"
      validate_absolute_path($_git_scl_path)
      $_gh_runner_path = join(["/opt/rh/${redhat_git_package}/root/usr/bin"] + $_gh_runner_path_base, ':')

      package { $redhat_git_package:
        ensure  => present,
        tag     => 'ghactions-git',
        require => Package['centos-release-scl-rh'],
      }
      # git lfs is only available on git218
      package { $redhat_git_lfs_package:
        ensure  => present,
        require => Package['centos-release-scl-rh'],
      }
    }
    default: {
      fail("${facts['os']['family']} is not supported")
    }
  }

  realize(Group[$_svc_account])
  realize(Account::User[$_svc_account])

  if $docker_access {
    realize(Group['docker'])
    User <| title == $_svc_account |> { groups +> 'docker'}
  }

  sudo::entry { "profile::${_svc_account}::runner":
    entry => @("SUDO"),
      ${_svc_account} ALL=(ALL) NOPASSWD:/home/${_svc_account}/repos/*/svc.sh
      Defaults:${_svc_account} !requiretty
      | SUDO
  }

  file {
    default:
      owner   => $_svc_account,
      group   => $_svc_account,
      require => Account::User[$_svc_account],
    ;
    "/home/${_svc_account}/.ssh/id_rsa":
      ensure    => file,
      mode      => '0600',
      show_diff => false,
      content   => "${unwrap($ghactions_private_key)}\n",
    ;
    "/home/${_svc_account}/repos":
      ensure => directory,
      mode   => '0755',
    ;
  }

  profile::vmpooler::insecure_private_ssh_key { 'pooler key for GitHub Actions agent':
    user      => $_svc_account,
    user_home => "/home/${_svc_account}",
    require   => Account::User[$_svc_account],
  }

  single_user_rvm::install { $_svc_account:
    unprivileged => true,
  }

  single_user_rvm::install_ruby { "ruby-${ruby_version}":
    user => $_svc_account,
  }

  $repos.each |$repo| {
    file {
      default:
        ensure  => file,
        owner   => $_svc_account,
        group   => $_svc_account,
        require => Account::User[$_svc_account],
        before  => Service["ghactions-${repo}"],
      ;
      "/home/${_svc_account}/repos/${repo}":
        ensure => directory,
        mode   => '0755',
      ;
      "/home/${_svc_account}/repos/${repo}/.path":
        mode    => '0644',
        content => $_gh_runner_path,
      ;
      "/home/${_svc_account}/repos/${repo}/runsvc.sh":
        mode    => '0755',
        content => epp('profile/ghactions/runner/runsvc.sh.epp', {
          'ruby_version' => $ruby_version,
          'git_scl_path' => $_git_scl_path,
        }),
      ;
    }

    if $disable_flag {
      $service_ensure = stopped
      $service_enable = false
    } else {
      $service_ensure = running
      $service_enable = true
    }

    systemd::unit_file { "ghactions-${repo}.service":
      content => epp('profile/ghactions/runner/service.epp', {
        'repo'        => $repo,
        'svc_account' => $_svc_account,
      }),
      owner   => $_svc_account,
      group   => $_svc_account,
      mode    => '0644',
    }
    ~> service { "ghactions-${repo}":
      ensure    => $service_ensure,
      enable    => $service_enable,
      tag       => ['ghactions-service'],
      subscribe => File[
        "/home/${_svc_account}/repos/${repo}/.path",
        "/home/${_svc_account}/repos/${repo}/runsvc.sh",
      ],
    }
  } # end $repos.each |$repo|
}
