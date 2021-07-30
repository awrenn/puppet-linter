class profile::monitoring::icinga2::web(
  $read_only_ldap_groups = ['org-products', 'org-bto'],
  $admin_ldap_groups = ['team-infracore', 'team-quality-engineering', 'team-release-engineering'],

  $icingaweb2_ldap_pass = undef,
){

  include profile::monitoring::icinga2::common
  include profile::ssl::ops
  include profile::nginx
  include profile::git

  $www_root = '/usr/share/icingaweb2'
  $icingaweb2_confdir = '/etc/icingaweb2'
  $fpm_socket = '/var/run/php5-fpm-icingaweb2.sock'

  class { 'phpfpm':
    poold_purge => true,
  }

  ini_setting { 'set_tz_php':
    section => 'PHP',
    path    => '/etc/php5/fpm/php.ini',
    setting => 'date.timezone',
    value   => 'America/Los_Angeles',
    require => Class['phpfpm'],
  }


  phpfpm::pool { 'icingaweb2_fpm':
    listen                    => $fpm_socket,
    pm                        => 'dynamic',
    pm_max_children           => 3,
    pm_start_servers          => 2,
    pm_min_spare_servers      => 2,
    pm_max_spare_servers      => 3,
    pm_max_requests           => 250,
    listen_owner              => 'www-data',
    listen_group              => 'icingaweb2',
    catch_workers_output      => true,
    security_limit_extensions => '.php',
    access_log                => '/var/log/phpfpm_icingaweb2_access.log',
    slowlog                   => '/var/log/phpfpm_icingaweb2_slow.log',
  }

  nginx::resource::server { 'icingaweb2_app':
    ensure               =>  present,
    ssl_redirect         => true,
    ssl                  => true,
    ssl_cert             => $::profile::ssl::ops::combined_file,
    ssl_key              => $::profile::ssl::ops::keyfile,
    www_root             => "${www_root}/public",
    use_default_location => false,
    index_files          => ['index.php'],
    server_name          => [ $facts['networking']['fqdn'] ],
  }

  nginx::resource::location { 'icingaweb2_redirect':
    ensure              => 'present',
    priority            => 500,
    ssl                 => true,
    ssl_only            => true,
    server              => 'icingaweb2_app',
    location            => '/',
    location_custom_cfg => {
              'rewrite' => '^/.*$ https://$server_name/icingaweb2',
    },
  }

  nginx::resource::location { 'icingaweb2_fastcgi_proxy':
    ensure                      => 'present',
    priority                    => 501,
    ssl                         =>  true,
    ssl_only                    => true,
    server                      => 'icingaweb2_app',
    location                    => '~ ^/icingaweb2/index\.php(.*)$',
    fastcgi_param               => {
          'SCRIPT_FILENAME'     => "${www_root}/public/index.php",
          'ICINGAWEB_CONFIGDIR' => $icingaweb2_confdir,
    },
    fastcgi                     => "unix:${fpm_socket}",
    location_custom_cfg_prepend => {
      fastcgi_index             => 'index.php;',
    },
  }

  nginx::resource::location { 'icingaweb2_root':
    location                    => '~ ^/icingaweb2(.+)?',
    priority                    => 502,
    ssl                         => true,
    ssl_only                    => true,
    server                      => 'icingaweb2_app',
    location_alias              => "${www_root}/public",
    index_files                 => ['index.php'],
    location_custom_cfg_prepend => {
        try_files               => '$1 $uri $uri/ /icingaweb2/index.php$is_args$args;',
    },
  }

  package { 'icingaweb2-module-monitoring':
    ensure => present,
    notify => Exec['enable_icingaweb2_mods'],
  }

  exec { 'enable_icingaweb2_mods':
    command     => 'icingacli module enable monitoring',
    refreshonly => true,
  }

  package { 'php5-cli':
    ensure => present,
  }

  class { 'icingaweb2':
    ido_db             => 'pgsql',
    ido_db_host        => $::profile::monitoring::icinga2::common::db_host,
    ido_db_pass        => $::profile::monitoring::icinga2::common::db_pass,
    ido_db_port        => $::profile::monitoring::icinga2::common::db_port,
    ido_db_name        => $::profile::monitoring::icinga2::common::application,
    ido_db_user        => $::profile::monitoring::icinga2::common::application,
    web_db             => 'pgsql',
    web_db_host        => $::profile::monitoring::icinga2::common::db_host,
    web_db_pass        => $::profile::monitoring::icinga2::common::db_pass,
    web_db_port        => $::profile::monitoring::icinga2::common::db_port,
    web_db_name        => 'icingaweb2',
    web_db_user        => 'icingaweb2',
    web_type           => 'db',
    install_method     => 'package',
    config_user        => 'icingaweb2',
    config_group       => 'www-data',
    config_dir_mode    => '770',
    config_dir_recurse => true,
  }


  $ldap_pw = unwrap(hiera('profile::ldap::client::sensitive_bindpw'))
  icingaweb2::config::resource_ldap { 'icinga2_ldap_resource':
    resource_host    => 'ldaps://ldap.puppetlabs.com',
    resource_port    => '636',
    resource_root_dn => 'cn=root,dc=puppetlabs,dc=com',
    resource_bind_dn => 'cn=icingaweb2,ou=service,ou=users,dc=puppetlabs,dc=com',
    resource_bind_pw => $icingaweb2_ldap_pass,
  }

# The filter parameter does not exist yet, but the option has been added to this resource since there is an outstanding PR.
  icingaweb2::config::authentication_ldap { 'icinga2_ldap_auth':
    auth_section        => 'icingaweb2_auth',
    auth_resource       => 'icinga2_ldap_resource',
    base_dn             => 'dc=puppetlabs,dc=com',
    user_name_attribute => 'uid',
  }

  $ldap_google_group_base = 'ou=googleGroups,dc=puppetlabs,dc=com'
  $ldap_admins = $admin_ldap_groups.map |$d| {
      $admin_results = ldapquery("(memberOf=cn=${d},${ldap_google_group_base})", 'uid')
      $admins = $admin_results.map |$a| { $a['uid'] }
    }

  if $ldap_admins != [] {
    icingaweb2::config::roles { 'admin_users_from_ldap':
      role_users       => join(flatten($ldap_admins), ','),
      role_permissions => '*',
    }
  }

  $ldap_members = $read_only_ldap_groups.map |$d| {
      $member_results = ldapquery("(memberOf=cn=${d},${ldap_google_group_base})", 'uid')
      $members = $member_results.map |$m| { $m['uid'] }
    }

  # Only assign people to one role.
  $deduped_ldap_members = flatten($ldap_members) - flatten($ldap_admins)
  if $deduped_ldap_members != [] {
    icingaweb2::config::roles { 'readonly_users_from_ldap':
      role_users       => join(flatten($deduped_ldap_members), ','),
      role_permissions => 'module/monitoring, monitoring/command/acknowledge-problem, monitoring/command/comment/add, monitoring/command/downtime/schedule',
    }
  }

  File {
    owner   => 'icingaweb2',
    group   => 'www-data',
  }

  file { "${icingaweb2_confdir}/modules/monitoring":
    ensure  => directory,
    mode    => '0760',
    owner   => 'icingaweb2',
    group   => 'www-data',
    recurse => true,
  }

  # TODO: Put this logic in the icingaweb2 module.
  file { "${icingaweb2_confdir}/enabledModules/monitoring":
    ensure  => link,
    target  => '/usr/share/icingaweb2/modules/monitoring',
    mode    => '0760',
    require => Package['icingaweb2-module-monitoring'],
  }

  file { "${icingaweb2_confdir}/modules/monitoring/config.ini":
    ensure  => present,
    mode    => '0760',
    require => File["${icingaweb2_confdir}/modules/monitoring"],
  }

  file { "${icingaweb2_confdir}/modules/monitoring/backends.ini":
    ensure  => present,
    mode    => '0760',
    require => File["${icingaweb2_confdir}/modules/monitoring"],
  }
  file { "${icingaweb2_confdir}/modules/monitoring/commandtransports.ini":
    ensure  => present,
    mode    => '0760',
    require => File["${icingaweb2_confdir}/modules/monitoring"],
  }

  ini_setting { 'set_monitoring_mod_config':
    section => 'security',
    path    => "${icingaweb2_confdir}/modules/monitoring/config.ini",
    setting => 'protected_customvars',
    value   => '"*pw,*pass*,community"',
    require => File["${icingaweb2_confdir}/modules/monitoring/config.ini"],
  }

  ini_setting { 'set_monitoring_mod_backends_type':
    section => 'icinga',
    path    => "${icingaweb2_confdir}/modules/monitoring/backends.ini",
    setting => 'type',
    value   => '"ido"',
    require => File["${icingaweb2_confdir}/modules/monitoring/backends.ini"],
  }

  ini_setting { 'set_monitoring_mod_backends_resource':
    section => 'icinga',
    path    => "${icingaweb2_confdir}/modules/monitoring/backends.ini",
    setting => 'resource',
    value   => '"icinga_ido"',
    require => File["${icingaweb2_confdir}/modules/monitoring/backends.ini"],
  }

  ini_setting { 'set_monitoring_mod_instances_transport':
    section => 'icinga',
    path    => "${icingaweb2_confdir}/modules/monitoring/commandtransports.ini",
    setting => 'transport',
    value   => '"local"',
    require => File["${icingaweb2_confdir}/modules/monitoring/commandtransports.ini"],
  }

  ini_setting { 'set_monitoring_mod_instances_path':
    section => 'icinga',
    path    => "${icingaweb2_confdir}/modules/monitoring/commandtransports.ini",
    setting => 'path',
    value   => '"/var/run/icinga2/cmd/icinga2.cmd"',
    require => File["${icingaweb2_confdir}/modules/monitoring/commandtransports.ini"],
  }
}
