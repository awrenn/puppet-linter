class profile::memcached::loadbalancer {
  profile_metadata::service { $title:
    human_name => 'HAProxy load balancer for memcached',
    notes      => @(END),
      As of 15 Jan 2020 there were no nodes using this profile. If you are reading
      this and know of it being applied somehwere please update the paramters for
      the `profile_metadata::service` resource in the manifest.
      | END
  }

  include profile::haproxy

  Haproxy::Backend {
    collect_exported => false,
  }

  Haproxy::Frontend {
    collect_exported => false,
  }
  haproxy::frontend { 'memcached':
    ports   => '11211',
    options => {
      'default_backend' => 'memcached',
      'mode'            => 'tcp',
    },
  }
  $test_key_name = "testkey_${hostname}"
  haproxy::backend { 'memcached':
    options => {
      'option'    => [
        'tcplog',
        'tcp-check',
      ],
      'balance'   => 'roundrobin',
      'mode'      => 'tcp',
      'tcp-check' => [
        'send stats\r\n',
        'expect string accepting_conns\ 1',
        # using join here to avoid escaping slashes and having multiple
        # levels of escaping
        # hostname is in test key in case two load balancers run the same check
        ['send set\ ',$test_key_name,'\ 0\ 30\ 4\r\n\test\r\n'].join,
        'expect string STORED',
        ['send delete\ ',$test_key_name,'\r\n'].join,
        'expect string DELETED',
      ],
    },
  }

  $balancer_members = unique(puppetdb_query("inventory {
    facts.classification.group = '${facts['classification']['group']}' and
    facts.classification.stage = '${facts['classification']['stage']}' and
    facts.whereami             = '${facts['whereami']}' and
    resources {
      type = 'Class' and
      title = 'Profile::Memcached'
    }
  }").map |$value| { $value['facts']['networking']['ip'] })

  $balancer_members.each |$client_ipaddress| {
    firewall { "150 allow memcached from ${client_ipaddress} in ${facts['classification']['group']} ${facts['classification']['stage']}}":
      proto  => 'tcp',
      action => 'accept',
      dport  => 11211,
      source => $client_ipaddress,
    }

    # only one balancer member should be primary
    # all other members should be backup and only used if the first is down
    $member_options = $client_ipaddress ? {
      $balancer_members[0] => ['check' ],
      default              => ['check', 'backup'],
    }

    haproxy::balancermember { "memcached_balancermember_${client_ipaddress}_${facts['classification']['group']}_${facts['classification']['stage']}":
      listening_service => 'memcached',
      server_names      => "memcached_${client_ipaddress}",
      ipaddresses       => $client_ipaddress,
      ports             => '11211',
      options           => $member_options,
    }
  }

}
