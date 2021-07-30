# Class: profile::jira::app::power_db_fields_pro
#
# This profile manages the database connection setting for
# the cPrime Power Database Fields PRO JIRA plugin. This
# plugin is being configured for the OpenReq project (BZAD-258)
#
class profile::jira::app::power_db_fields_pro (
  String[1] $creds_content,
) {

  class { 'profile::cloud_sql_proxy':
    configdir          => '/etc/cloudsql/',
    local_port         => $local_port,
    instance_id        => 'bto-bizapps-openreq-prod:us-central1:openreq-psql',
    creds_file_name    => 'openreq-service-account.json',
    creds_file_content => $creds_content,
  }

}
