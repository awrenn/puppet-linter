# Users in Icinga determine where notifications go
class profile::monitoring::icinga2::users (
  Hash[String[1], Profile::Monitoring::Icinga2::User::Configuration] $configuration,
) {

  include profile::monitoring::icinga2::common

  $hipchat_api_key = $::profile::monitoring::icinga2::common::notification_credentials['hipchat_api_key']
  $jira_user = $::profile::monitoring::icinga2::common::notification_credentials['jira_user']
  $jira_password = $::profile::monitoring::icinga2::common::notification_credentials['jira_password']

  $configuration.each |$user, $services| {
    # Each user might alert to PagerDuty and/or send messages to HipChat. This
    # builds up the parameters for the user resource.

    if $services['pagerduty_api_key'] {
      $pager_param = { pager => $services['pagerduty_api_key'] }
    } else {
      $pager_param = {}
    }

    if $services['hipchat_room_id'] {
      $hipchat_param = {
        vars => {
          'hipchat_id' => $services['hipchat_room_id'],
        },
      }
    } else {
      $hipchat_param = {}
    }

    icinga2::object::user { $user:
      * => $pager_param + $hipchat_param,
    }

    $notification_params = {
      notify_pagerduty => $services['notify_pagerduty'],
      notify_hipchat   => $services['notify_hipchat'],
      notify_jira      => $services['notify_jira'],
      jira_project     => $services['jira_project'],
      jira_ticket_type => $services['jira_ticket_type'],
    }.filter |$x| { $x[1] != undef }

    profile::monitoring::icinga2::notifications { $user:
      hipchat_api_key => $hipchat_api_key,
      jira_user       => $jira_user,
      jira_password   => $jira_password,
      *               => $notification_params,
    }
  }
}
