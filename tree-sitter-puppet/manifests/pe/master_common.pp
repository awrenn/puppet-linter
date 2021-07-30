#
# Profile to manage PE master / compiler settings that aren't managed by the puppet_enterprise modules
#
# @param $ldap_server [String] The canonical LDAP server to use for all connections.
# @param $ldap_base [String] The basedn used when querying LDAP.
# @param $ldap_user [String] The username used when querying LDAP.
# @param $ldap_pass Sensitive[[String]] The password used when querying LDAP.
# @param $restart_puppetserver [Boolean] Whether to restart pe-puppetserver every six hours on a rolling basis.
# @param $cache_environments [Boolean] Whether to cache environment data by default or not.
#
class profile::pe::master_common (
  String[1] $ldap_server                           = 'ldap.puppetlabs.com',
  String[1] $ldap_base                             = lookup('profile::ldap::client::basedn'),
  String[1] $ldap_user                             = lookup('profile::ldap::client::binddn'),
  Sensitive[String[1]] $ldap_pass                  = lookup('profile::ldap::client::sensitive_bindpw'),
  Boolean $restart_puppetserver                    = false,
  Optional[String[1]] $pdb_submit_only_server_urls = undef,
) {
  profile_metadata::service { $title:
    human_name        => 'Puppet compiler',
    team              => dio,
    end_users         => ['notify-infracore@puppet.com'],
    escalation_period => 'global-workhours',
    downtime_impact   => "Can't make changes to infrastructure",
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/OPS/SysOps+Internal+Puppet+Infrastructure+Service+Docs',
    ],
  }

  # Puppet modules telemetry
  include dropsonde
  include cd4pe::impact_analysis
  include profile::eyaml::private
  include node_encrypt::certificates
  Puppet_authorization::Rule <| |> ~> Service['pe-puppetserver']

  $puppet_conf = '/etc/puppetlabs/puppet/puppet.conf'

  # TODO: Fix this; conflicts with puppet_agent module
  # # puppet.conf has an LDAP password in it; make sure it's not world-readable.
  # file { $puppet_conf:
  #   ensure => file,
  #   owner  => 'pe-puppet',
  #   group  => 'pe-puppet',
  #   mode   => '0600',
  # }

  package { 'deep_merge puppet_gem': # Depedency for autosign
    ensure   => '1.2.1',
    name     => 'deep_merge',
    provider => 'puppet_gem',
  }

  package { 'autosign puppetserver_gem':
    ensure   => '0.1.4',
    name     => 'autosign',
    provider => 'puppetserver_gem',
    notify   => Service['pe-puppetserver'],
  }

  package { 'faraday puppetserver_gem':
    ensure   => '1.0.1',
    name     => 'faraday',
    provider => 'puppetserver_gem',
    notify   => Service['pe-puppetserver'],
  }

  package { 'nokogiri puppetserver_gem':
    ensure   => '1.10.9',
    name     => 'nokogiri',
    provider => 'puppetserver_gem',
    notify   => Service['pe-puppetserver'],
  }

  package {
    default:
      ensure => '2.0.1',
      name   => 'toml-rb',
    ;
    'toml-rb puppet_gem':
      provider => 'puppet_gem',
    ;
    'toml-rb puppetserver_gem':
      provider => 'puppetserver_gem',
      notify   => Service['pe-puppetserver'],
    ;
  }

  ini_setting {
    default:
      ensure  => present,
      section => 'master',
      path    => $puppet_conf,
      notify  => Service['pe-puppetserver'],
    ;
    'default_manifest-master':
      ensure  => absent,
      setting => 'default_manifest',
    ;
    'default_manifest-main':
      ensure  => absent,
      section => 'main',
      setting => 'default_manifest',
    ;
    'enable_i18n':
      setting => 'disable_i18n',
      value   => 'false',
    ;
    'ldapserver':
      setting => 'ldapserver',
      value   => $ldap_server,
    ;
    'ldapport':
      setting => 'ldapport',
      value   => '636',
    ;
    'ldapbase':
      setting => 'ldapbase',
      value   => $ldap_base,
    ;
    'ldapuser':
      setting => 'ldapuser',
      value   => $ldap_user,
    ;
    'ldappassword':
      setting => 'ldappassword',
      value   => unwrap($ldap_pass),
    ;
    'ldaptls':
      setting => 'ldaptls',
      value   => true,
    ;
    'usecacheonfailure':
      section => 'main',
      setting => 'usecacheonfailure',
      value   => false,
    ;
  }

  # PuppetDB Settings
  if $pdb_submit_only_server_urls {
    ini_setting { 'puppetdb_submit_only_server_urls':
      ensure  => present,
      section => 'main',
      path    => '/etc/puppetlabs/puppet/puppetdb.conf',
      setting => 'submit_only_server_urls',
      value   => $pdb_submit_only_server_urls,
      notify  => Service['pe-puppetserver'],
    }
  } else {
    ini_setting { 'puppetdb_submit_only_server_urls':
      ensure  => absent,
      section => 'main',
      path    => '/etc/puppetlabs/puppet/puppetdb.conf',
      setting => 'submit_only_server_urls',
      notify  => Service['pe-puppetserver'],
    }
  }

  # LDAP
  package {
    default:
      ensure => '0.11',
      name   => 'net-ldap',
    ;
    'net-ldap puppetserver_gem':
      provider => 'puppetserver_gem',
      notify   => Service['pe-puppetserver'],
    ;
    'net-ldap puppet_gem':
      provider => 'puppet_gem',
    ;
  }

  # used by site/puppetlabs/lib/puppet/functions/to_symbolized_yaml.rb
  # the agent gem is used when running `puppet lookup`
  package {
    default:
      ensure => '3.1.0',
      name   => 'facets',
    ;
    'facets puppetserver_gem':
      provider => 'puppetserver_gem',
      notify   => Service['pe-puppetserver'],
    ;
    'facets puppet_gem':
      provider => 'puppet_gem',
    ;
  }

  package { 'remove safe_yaml from puppetserver_gem':
    ensure   => absent,
    name     => 'safe_yaml',
    provider => 'puppetserver_gem',
    notify   => Service['pe-puppetserver'],
  }

  file { '/etc/puppetlabs/puppet/ldap_ca.pem':
    owner  => 'root',
    group  => '0',
    mode   => '0644',
    source => 'puppet:///modules/profile/ssl/ldap.puppetlabs.com_inter.crt',
  }

  # mco is nolonger a thing for us
  file { '/root/.mcollective':
    ensure => absent,
  }

  if $restart_puppetserver {
    cron { 'restart puppetserver':
      ensure  => present,
      command => '/usr/bin/systemctl restart pe-puppetserver.service',
      minute  => 57,
      hour    => [0, 6, 12, 18].map |$x| { ($x + $facts['classification']['number']) % 24 },
    }
  } else {
    cron { 'restart puppetserver':
      ensure => absent,
    }
  }

  tidy { 'puppetserver heap dumps':
    path    => '/var/log/puppetlabs/puppetserver/',
    matches => '*.hprof',
    recurse => 1,
    age     => '1w',
  }

  # Group for team froyo debugging
  Account::User <| groups == 'froyo' |>
  ssh::allowgroup { 'froyo': }
  sudo::allowgroup { 'froyo': }
  Account::User <| groups == 'installer-mgnt' |>
  ssh::allowgroup { 'installer-mgnt': }
  sudo::allowgroup { 'installer-mgnt': }

  # up root's open files soft limit
  # r10k can open too many files, so this bumps the default soft limit a bit.
  file_line { 'root_nofile_limit':
    ensure => present,
    path   => '/etc/security/limits.conf',
    line   => 'root soft nofile 4096',
    match  => '^root\s+soft\s+nofile',
  }

  # Ensure the compilers always talk to the master instead of the load balancer
  $master = puppetdb_query("inventory {
    resources {
      (type = 'Class' and title = 'Role::Pe::Master')
    }
  }")

  if $master[0] {
    host { "puppet.${master[0]['facts']['networking']['domain']}":
      ensure => present,
      ip     => $master[0]['facts']['networking']['ip'],
    }
  }

  # Lidar deprovisioning
  ini_setting { 'disable lidar':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'master',
    setting => 'reports',
    value   => 'puppetdb',
    notify  => Service['pe-puppetserver'],
  }

  file { '/etc/puppetlabs/puppet/lidar_routes.yaml':
    ensure => absent,
  }

  ini_setting { 'disable lidar_routes.yaml':
    ensure  => absent,
    section => 'master',
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    setting => 'route_file',
    notify  => Service['pe-puppetserver'],
  }

  file { '/etc/puppetlabs/puppet/lidar.yaml':
    ensure  => absent,
  }
}

