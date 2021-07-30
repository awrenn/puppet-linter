class profile::p9openstack::proxy(
  String[1] $canonical_fqdn = $facts['networking']['fqdn']
) {
  profile_metadata::service { $title:
    human_name => 'Platform9 OpenStack proxy',
    team       => dio,
  }

  include profile::nginx
  include profile::ssl::ops

  $dh_name = lookup('ssl::dh_param_name')

  # Puppet DB Query to get all compute nodes.
  $hosts = puppetdb_query("inventory { resources { type = 'Class' and title = 'Role::P9openstack::Compute' } and facts.classification.stage = '${facts['stage']}' order by certname asc }")

  class { 'profile::nginx::redirect::all':
    canonical_fqdn => $canonical_fqdn,
  }

  file { '/etc/nginx/conf.d/01_proxy.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => epp('profile/p9openstack/proxy/01_proxy.conf.epp', {
      'hosts'          => $hosts,
      'certfile'       => $profile::ssl::ops::cert_file,
      'keyfile'        => $profile::ssl::ops::keyfile,
      'dh_name'        => "${ssl::params::key_dir}/${dh_name}",
      'canonical_fqdn' => $canonical_fqdn
    }),
    notify  => Service['nginx'],
  }

}
