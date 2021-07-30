# Enable cold migration
class profile::p9openstack::migration::cold {
  # Ensure pf9 can ssh between every host in the same group/context/stage.
  ssh::key::collector { 'pf9': }
  ssh::key { 'pf9':
    key_path           => '/opt/pf9/home/.ssh/id_rsa',
    manage_known_hosts => false,
    target_query       => @("QUERY"),
      class[profile::p9openstack::migration::cold]
      and group = "${facts['group']}"
      and stage = "${facts['stage']}"
      |-QUERY
  }
}
