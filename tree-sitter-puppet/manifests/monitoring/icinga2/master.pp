class profile::monitoring::icinga2::master (
  String[1] $qe_apiuser_pass,
  String[1] $re_apiuser_pass,
) {
  profile_metadata::service { $title:
    human_name        => 'Icinga2 Master',
    owner_uid         => 'heath',
    team              => dio,
    end_users         => ['discuss-sre@puppet.com'],
    escalation_period => '24/7',
    downtime_impact   => "Hosts aren't monitored.",
    doc_urls          => [
      'https://confluence.puppetlabs.com/display/SRE/Icinga2+Infrastructure',
      'https://confluence.puppetlabs.com/display/SRE/Icinga2',
    ],
  }

  include profile::monitoring::icinga2::common
  include profile::monitoring::icinga2::users
  include profile::monitoring::icinga2::dependencies
  include profile::monitoring::icinga2::groups
  include profile::monitoring::icinga2::timeperiods
  require profile::monitoring::icinga2::server
  include profile::puppetadmins

  class { 'icinga2::feature::ido_pgsql':
    host     => $profile::monitoring::icinga2::common::db_host,
    port     => $profile::monitoring::icinga2::common::db_port,
    user     => $profile::monitoring::icinga2::common::application,
    password => $profile::monitoring::icinga2::common::db_pass,
    database => $profile::monitoring::icinga2::common::application,
  }

  Icinga2::Object::Notificationcommand {
    cmd_path => 'PuppetPluginDir',
  }
  # Set up the HipChat integration command
  icinga2::object::notificationcommand { 'hipchat-host-notifier':
    command   => [ "\"/hipchat_notifier.py\"" ],
    arguments => {
      '--check-type'   => {
        'value'      => 'host',
        'repeat_key' => false,
        'required'   => true,
      },
      '--auth-token'   => {
        'value'      => '$auth_token$',
        'repeat_key' => false,
        'required'   => true,
      },
      '--monitor-host' => {
        'value'      => '$monitor_host$',
        'repeat_key' => false,
        'required'   => true,
      },
      '--room-id'      => {
        'value'      => '$room_id$',
        'repeat_key' => false,
        'required'   => true,
      },
    },
    env       => {
      'ICINGA_HOSTDISPLAYNAME'     => '"$host.display_name$"',
      'ICINGA_HOSTNAME'            => '"$host.display_name$"',
      'ICINGA_HOSTALIAS'           => '"$host.name$"',
      'ICINGA_CHECKSOURCE'         => '"$host.check_source$"',
      'ICINGA_HOSTSTATEID'         => '"$host.state_id$"',
      'ICINGA_HOSTOUTPUT'          => '"$host.output$"',
      'ICINGA_HOSTSTATE'           => '"$host.state$"',
      'ICINGA_NOTIFICATIONTYPE'    => '"$notification.type$"',
      'ICINGA_NOTIFICATIONAUTHOR'  => '"$notification.author$"',
      'ICINGA_NOTIFICATIONCOMMENT' => '"$notification.comment$"',
    },
  }

  icinga2::object::notificationcommand { 'hipchat-service-notifier':
    command   => [ "\"/hipchat_notifier.py\"" ],
    arguments => {
      '--check-type'   => {
        'value'      => 'service',
        'repeat_key' => false,
        'required'   => true,
      },
      '--auth-token'   => {
        'value'      => '$auth_token$',
        'repeat_key' => false,
        'required'   => true,
      },
      '--monitor-host' => {
        'value'      => '$monitor_host$',
        'repeat_key' => false,
        'required'   => true,
      },
      '--room-id'      => {
        'value'      => '$room_id$',
        'repeat_key' => false,
        'required'   => true,
      },
    },
    env       => {
      'ICINGA_HOSTNAME'            => '"$host.display_name$"',
      'ICINGA_HOSTALIAS'           => '"$host.name$"',
      'ICINGA_CHECKSOURCE'         => '"$service.check_source$"',
      'ICINGA_SERVICESTATEID'      => '"$service.state_id$"',
      'ICINGA_SERVICEDISPLAYNAME'  => '"$service.display_name$"',
      'ICINGA_SERVICEOUTPUT'       => '"$service.output$"',
      'ICINGA_SERVICESTATE'        => '"$service.state$"',
      'ICINGA_SERVICEACTIONURL'    => '"$service.action_url$"',
      'ICINGA_SERVICENOTESURL'     => '"$service.notes_url$"',
      'ICINGA_NOTIFICATIONTYPE'    => '"$notification.type$"',
      'ICINGA_NOTIFICATIONAUTHOR'  => '"$notification.author$"',
      'ICINGA_NOTIFICATIONCOMMENT' => '"$notification.comment$"',
    },
  }


  icinga2::object::notificationcommand { 'jira-host-notifier':
    command   => [ "\"/jira_notifier.py\"" ],
    arguments => {
      '--object-type'  => {
        'value'      => 'Host',
        'repeat_key' => false,
        'required'   => true,
      },
      '--username'     => {
        'value'      => '$username$',
        'repeat_key' => false,
        'required'   => true,
      },
      '--password'     => {
        'value'      => '$password$',
        'repeat_key' => false,
        'required'   => true,
      },
      '--jira-url'     => {
        'value'      => '$jira_url$',
        'repeat_key' => false,
        'required'   => true,
      },
      '--project'      => {
        'value'      => '$jira_project$',
        'repeat_key' => false,
        'required'   => true,
      },
      '--ticket-type'  => {
        'value'      => '$jira_ticket_type$',
        'repeat_key' => false,
        'required'   => true,
      },
      '--monitor-host' => {
        'value'      => '$monitor_host$',
        'repeat_key' => false,
        'required'   => true,
      },
    },
    env       => {
      'ICINGA_HOSTDISPLAYNAME'     => '"$host.display_name$"',
      'ICINGA_HOSTNAME'            => '"$host.display_name$"',
      'ICINGA_HOSTALIAS'           => '"$host.name$"',
      'ICINGA_HOSTSTATEID'         => '"$host.state_id$"',
      'ICINGA_HOSTOUTPUT'          => '"$host.output$"',
      'ICINGA_HOSTSTATE'           => '"$host.state$"',
      'ICINGA_LASTHOSTSTATE'       => '"$host.last_state$"',
      'ICINGA_NOTIFICATIONTYPE'    => '"$notification.type$"',
      'ICINGA_NOTIFICATIONAUTHOR'  => '"$notification.author$"',
      'ICINGA_NOTIFICATIONCOMMENT' => '"$notification.comment$"',
    },
  }

  icinga2::object::notificationcommand { 'jira-service-notifier':
    command   => [ "\"/jira_notifier.py\"" ],
    arguments => {
      '--object-type'  => {
        'value'      => 'Service',
        'repeat_key' => false,
        'required'   => true,
      },
      '--username'     => {
        'value'      => '$username$',
        'repeat_key' => false,
        'required'   => true,
      },
      '--password'     => {
        'value'      => '$password$',
        'repeat_key' => false,
        'required'   => true,
      },
      '--jira-url'     => {
        'value'      => '$jira_url$',
        'repeat_key' => false,
        'required'   => true,
      },
      '--project'      => {
        'value'      => '$jira_project$',
        'repeat_key' => false,
        'required'   => true,
      },
      '--ticket-type'  => {
        'value'      => '$jira_ticket_type$',
        'repeat_key' => false,
        'required'   => true,
      },
      '--monitor-host' => {
        'value'      => '$monitor_host$',
        'repeat_key' => false,
        'required'   => true,
      },
    },
    env       => {
      'ICINGA_HOSTNAME'            => '"$host.display_name$"',
      'ICINGA_HOSTALIAS'           => '"$host.name$"',
      'ICINGA_SERVICESTATEID'      => '"$service.state_id$"',
      'ICINGA_SERVICEDISPLAYNAME'  => '"$service.display_name$"',
      'ICINGA_SERVICEOUTPUT'       => '"$service.output$"',
      'ICINGA_SERVICESTATE'        => '"$service.state$"',
      'ICINGA_LASTSERVICESTATE'    => '"$service.last_state$"',
      'ICINGA_SERVICEACTIONURL'    => '"$service.action_url$"',
      'ICINGA_SERVICENOTESURL'     => '"$service.notes_url$"',
      'ICINGA_NOTIFICATIONTYPE'    => '"$notification.type$"',
      'ICINGA_NOTIFICATIONAUTHOR'  => '"$notification.author$"',
      'ICINGA_NOTIFICATIONCOMMENT' => '"$notification.comment$"',
    },
  }

  # Need Python elasticsearch module for Zpr monitoring
  python::pip { 'elasticsearch':
    ensure   => 'present',
  }

  # pagerduty script dependencies
  package { ['libwww-perl', 'libcrypt-ssleay-perl']:
    ensure => present,
  }

  python::pip { 'icinga_notifier':
    ensure       => 'present',
    install_args => "--extra-index-url ${profile::pypi::url}",
  }
  include python_ldap

  cron { 'pagerduty cron':
    command => "${profile::monitoring::icinga2::common::plops_plugin_dir}/pagerduty_icinga.pl flush",
    require => File["${profile::monitoring::icinga2::common::plops_plugin_dir}/pagerduty_icinga.pl"],
  }


    # This sets up a cron to run a series of tasks when the on call rotation changes every week.
    if $facts['classification']['stage'] == 'prod' {
      $hipchat_room_id = '3076812' # SRE
      $hipchat_url = 'https://puppet.hipchat.com/v2'
      $hipchat_oauth_secret = $profile::monitoring::icinga2::common::notification_credentials['hipchat_oauth_secret']
      $hipchat_oauth_id = $profile::monitoring::icinga2::common::notification_credentials['hipchat_oauth_id']
      $pd_auth_token = $profile::monitoring::icinga2::common::notification_credentials['pagerduty_auth_token']
      $pd_url = 'https://puppetlabs.pagerduty.com/api/v1'
      $pd_escalation_policy_id = 'P0YHPDC' # SysOps (InfraCore) Primary
      $ldap_url = hiera('profile::ldap::client::uri')
      $ldap_basedn = hiera('profile::ldap::client::basedn')
      $ldap_binddn = hiera('profile::ldap::client::binddn')
      $ldap_bindpassword = unwrap(hiera('profile::ldap::client::sensitive_bindpw'))

      $oncall_updater_path = "${profile::monitoring::icinga2::common::plops_plugin_dir}/oncall_updater.py"
      $oncall_updater_cmd = join(any2array({
        $oncall_updater_path        => '',
        '--hipchat-room-id'         => "'${hipchat_room_id}'",
        '--hipchat-oauth-id'        => "'${hipchat_oauth_id}'",
        '--hipchat-oauth-secret'    => "'${hipchat_oauth_secret}'",
        '--hipchat-url'             => "'${hipchat_url}'",
        '--pd-auth-token'           => "'${pd_auth_token}'",
        '--pd-url'                  => "'${pd_url}'",
        '--pd-escalation-policy-id' => "'${pd_escalation_policy_id}'",
        '--ldap-url'                => "'${ldap_url}'",
        '--ldap-basedn'             => "'${ldap_basedn}'",
        '--ldap-binddn'             => "'${ldap_binddn}'",
        '--ldap-bindpassword'       => "'${ldap_bindpassword}'",
      }), ' ')

      cron { 'oncall updater':
        command =>"${oncall_updater_cmd} 2>&1 | logger -t oncall_updater",
        weekday => 2,
        hour    => 10,
        minute  => 1,
      }
  }

  file { "${profile::monitoring::icinga2::common::plops_plugin_dir}/pagerduty_icinga.pl":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/profile/monitoring/icinga2/plugins/pagerduty_icinga.pl',
    require =>  Package['libwww-perl', 'libcrypt-ssleay-perl'],
  }

  file { '/tmp/pagerduty_icinga':
    ensure  => present,
    owner   => $profile::monitoring::icinga2::common::icinga2_user,
    group   => $profile::monitoring::icinga2::common::icinga2_user,
    mode    => '0755',
    recurse => true,
  }

  icinga2::object::notificationcommand { 'pagerduty-service-notifier':
    command   => [ '"/pagerduty_icinga.pl"' ],
    arguments => {
      'enqueue'           => {
        'order'    => '-1',
      },
      '-f'                => {
        'required' => true,
        'value'    => 'pd_nagios_object=service',
      },
      '--blacklist-field' => {
        'required'   => true,
        'value'      => '$field_blacklist$',
        'repeat_key' => true,
      },
    },
    env       => {
      'ICINGA_CONTACTPAGER'        => '"$user.pager$"',
      'ICINGA_NOTIFICATIONTYPE'    => '"$notification.type$"',
      'ICINGA_NOTIFICATIONAUTHOR'  => '"$notification.author$"',
      'ICINGA_NOTIFICATIONCOMMENT' => '"$notification.comment$"',
      'ICINGA_SERVICEDESC'         => '"$service.name$"',
      'ICINGA_HOSTALIAS'           => '"$host.name$"',
      'ICINGA_HOSTDISPLAYNAME'     => '"$host.display_name$"',
      'ICINGA_HOSTNAME'            => '"$host.display_name$"',
      'ICINGA_SERVICESTATE'        => '"$service.state$"',
      'ICINGA_SERVICEOUTPUT'       => '"$service.output$"',
    },
  }

  icinga2::object::notificationcommand { 'pagerduty-host-notifier':
    command   => [ '"/pagerduty_icinga.pl"' ],
    arguments => {
      'enqueue'           => {
        'order'                 => '-1',
      },
      '-f'                => {
        'required' => true,
        'value'    => 'pd_nagios_object=host',
      },
      '--blacklist-field' => {
        'required'   => true,
        'value'      => '$field_blacklist$',
        'repeat_key' => true,
      },
    },
    env       => {
      'ICINGA_CONTACTPAGER'        => '"$user.pager$"',
      'ICINGA_NOTIFICATIONTYPE'    => '"$notification.type$"',
      'ICINGA_NOTIFICATIONAUTHOR'  => '"$notification.author$"',
      'ICINGA_NOTIFICATIONCOMMENT' => '"$notification.comment$"',
      'ICINGA_HOSTALIAS'           => '"$host.name$"',
      'ICINGA_HOSTDISPLAYNAME'     => '"$host.display_name$"',
      'ICINGA_HOSTNAME'            => '"$host.display_name$"',
      'ICINGA_HOSTSTATE'           => '"$host.state$"',
      'ICINGA_HOSTOUTPUT'          => '"$host.output$"',
    },
  }

  # Configure the Graphite writer to send Icinga2 metrics.
  icinga2::object::graphitewriter { 'graphite':
    host_name_template    => '"icinga2.$host.display_name$.host.$host.check_command$"',
    service_name_template => '"icinga2.$host.display_name$.services.$service.name$.$service.check_command$"',
    host                  => 'graphite.ops.puppetlabs.net',
    port                  => '2003',
  }

  $apiuser_pass = hiera('icinga2_apiuser_pass')
  icinga2::object::apiuser { 'icinga2':
    password => $apiuser_pass,
  }

  icinga2::object::apiuser { 'qe-team':
    password => $qe_apiuser_pass,
  }

  icinga2::object::apiuser { 're-team':
    password => $re_apiuser_pass,
  }
}
