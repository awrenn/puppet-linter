##
#
class profile::repo::proxy {

  meta_motd::register { 'Squid repository caching proxy': }

  class { 'squid': }

  squid::acl { 'Safe_ports':
    type    => port,
    entries => ['80','443'],
  }

  squid::http_access { 'Safe_ports':
    action => allow,
  }

  squid::http_access{ '!Safe_ports':
    action => deny,
  }

  squid::http_port { '3128': }
}

