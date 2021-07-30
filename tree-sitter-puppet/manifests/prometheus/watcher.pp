# This profile sets up a Prometheus server for watching that we can access
# the k8s cluster where the rest of our metrics collection happens.
# It is intended as a watch the watcher kind of thing - we want to run this
# kind of thing in k8s but need something outside k8s to make sure the pathway
# to the k8s API in Google is functioning.
class profile::prometheus::watcher (
  Sensitive[String[1]] $sensitive_remote_write_password,
) {
  include prometheus
  include prometheus::blackbox_exporter

  profile_metadata::service { $title:
    human_name      => 'Prometheus Watcher',
    owner_uid       => 'gene.liverman',
    team            => dio,
    end_users       => ['notify-infracore@puppet.com'],
    downtime_impact => 'No external validation of causeway access',
  }

  realize(Account::User['prometheus'])

  file {
    '/vault':
      ensure => directory
    ;
    '/vault/secrets':
      ensure => directory
    ;
    '/vault/secrets/grafana-apikey':
      ensure    => file,
      content   => $sensitive_remote_write_password.unwrap,
      show_diff => false,
      before    => Class['Prometheus'],
    ;
  }
}
