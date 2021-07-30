define profile::monitoring::icinga2::notifications (
  String[1]                                 $hipchat_api_key,
  String[1]                                 $jira_user,
  String[1]                                 $jira_password,
  String[1]                                 $jira_url         = 'https://tickets.puppetlabs.com',
  Optional[Pattern[/\A[A-Za-z]+\Z/]]        $jira_project     = 'SRE',
  Optional[Pattern[/\A[A-Za-z]+\Z/]]        $jira_ticket_type = 'Incident',
  Variant[Boolean, Enum['host', 'service']] $notify_pagerduty = false,
  Variant[Boolean, Enum['host', 'service']] $notify_hipchat   = false,
  Variant[Boolean, Enum['host', 'service']] $notify_jira      = false,
  String[1]                                 $user             = $title,
) {
  if $notify_pagerduty == true or $notify_pagerduty == 'host' {
    icinga2::object::apply_notification_to_host { "${user}-PagerDuty-Host-Notifications":
      users        => [$user],
      command      => 'pagerduty-host-notifier',
      period       => 'host.vars.notification_period',
      assign_where => "host.vars.escalate == true && host.vars.owner == \"${user}\"",
      vars         => {
        'monitor_host'    => $trusted['certname'],
        'field_blacklist' => ['SERVICECHECKCOMMAND'],
      },
    }
  }
  if $notify_pagerduty == true or $notify_pagerduty == 'service' {
    icinga2::object::apply_notification_to_service { "${user}-PagerDuty-Service-Notifications":
      users        => [$user],
      command      => 'pagerduty-service-notifier',
      period       => 'service.vars.notification_period',
      types        => ['Problem', 'Acknowledgement', 'Recovery'],
      states       => ['Critical', 'OK'],
      assign_where => @("CONDITION"/L),
        service.vars.escalate == true \
        && ((service.vars.owner == "${user}") \
            || (host.vars.owner == "${user}" && service.vars.owner == ""))
        |-CONDITION
      vars         => {
        'monitor_host'    => $trusted['certname'],
        'field_blacklist' => ['SERVICECHECKCOMMAND'],
      },
    }
  }
  if $notify_hipchat == true or $notify_hipchat == 'host' {
    icinga2::object::apply_notification_to_host { "${user}-HipChat-Host-Notifications":
      users        => [$user],
      command      => 'hipchat-host-notifier',
      assign_where => "(host.vars.notify_chat == true || host.vars.escalate == true) && host.vars.owner == \"${user}\"",
      vars         => {
        'monitor_host' => $trusted['certname'],
        'auth_token'   => $hipchat_api_key,
        'room_id'      => '$user.vars.hipchat_id$',
      },
    }
  }
  if $notify_hipchat == true or $notify_hipchat == 'service' {
    icinga2::object::apply_notification_to_service { "${user}-HipChat-Service-Notifications":
      users        => [$user],
      command      => 'hipchat-service-notifier',
      states       => ['Critical', 'Warning', 'Unknown', 'OK'],
      assign_where => @("CONDITION"/L),
        (service.vars.notify_chat == true \
         || (host.vars.notify_chat == true && service.vars.notify_chat == "") \
         || service.vars.escalate == true) \
        && ((service.vars.owner == "${user}") \
            || (host.vars.owner == "${user}" && service.vars.owner == ""))
        |-CONDITION
      vars         => {
        'monitor_host' => $trusted['certname'],
        'auth_token'   => $hipchat_api_key,
        'room_id'      => '$user.vars.hipchat_id$',
      },
    }
  }
  if $notify_jira == true or $notify_jira == 'host' {
    icinga2::object::apply_notification_to_host { "${user}-Jira-Host-Incidents":
      users        => [$user],
      command      => 'jira-host-notifier',
      interval     => '0',
      assign_where => "(host.vars.create_incident_ticket == true || host.vars.escalate == true) && host.vars.owner == \"${user}\"",
      vars         => {
        'monitor_host'     => $trusted['certname'],
        'jira_url'         => $jira_url,
        'jira_project'     => $jira_project,
        'jira_ticket_type' => $jira_ticket_type,
        'username'         => $jira_user,
        'password'         => $jira_password,
      },
    }
  }
  if $notify_jira == true or $notify_jira == 'service' {
    icinga2::object::apply_notification_to_service { "${user}-Jira-Service-Incidents":
      users        => [$user],
      command      => 'jira-service-notifier',
      interval     => '0',
      states       => ['Critical', 'Unknown', 'Warning', 'OK'],
      types        => ['Problem', 'Recovery'],
      assign_where => @("CONDITION"/L),
        (service.vars.create_incident_ticket == true || service.vars.escalate == true) \
        && ((service.vars.owner == "${user}") \
            || (host.vars.owner == "${user}" && service.vars.owner == ""))
        |-CONDITION
      vars         => {
        'monitor_host'     => $trusted['certname'],
        'jira_url'         => $jira_url,
        'jira_project'     => $jira_project,
        'jira_ticket_type' => $jira_ticket_type,
        'username'         => $jira_user,
        'password'         => $jira_password,
      },
    }
  }
}
