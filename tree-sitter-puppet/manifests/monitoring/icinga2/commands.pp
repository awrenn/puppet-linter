class profile::monitoring::icinga2::commands {

  include profile::monitoring::icinga2::common

  # If a check requires sudo then it should be added to this array.
  $icinga2_sudo_checks = [
    "${::profile::monitoring::icinga2::common::icinga2_user} ALL=(ALL) NOPASSWD:${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_puppet_agent.py",
    "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_certs.rb",
    "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_service_status.py",
    "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_exit.rb",
    "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_postgres.pl",
    "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_puppet_environments.py",
    "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_jenkins.py",
    "${::profile::monitoring::icinga2::common::plugin_dir}/check_procs",
    "${::profile::monitoring::icinga2::common::plugin_dir}/check_zpr_job.py",
    "${::profile::monitoring::icinga2::common::plugin_dir}/check_ssl_cert",
    "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_tsp_queue_time.py",
    "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_zpr_canary.py",
    "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_docker_datafile.py",
    "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_docker_thinpool.py",
    "${::profile::monitoring::icinga2::common::plops_plugin_dir}/restart_service.sh",
  ]

  sudo::entry{ 'icinga2_checks':
    entry => $icinga2_sudo_checks.join(','),
  }

  # Icinga2 check command objects should be contained here. This is temporary until we get rid of using ssh based checks.
  if $::profile::monitoring::icinga2::common::agent_provider == 'icinga2-client' {
    Icinga2::Object::Checkcommand {
      cmd_path => '',
    }
    Icinga2::Object::Eventcommand {
      cmd_path => '',
    }

    icinga2::object::checkcommand { 'aggregated-check':
      command   => [ '/usr/local/bin/aggcheck' ],
      # The Erlang VM needs to have a HOME directory set and Icinga2 does not exec child processes with this environment variable because it generally isn't used for anything.
      env       => {
        'HOME' => '/tmp',
      },
      arguments => {
        # check name will be prepended to check output; use something short
        '--name'           => {
          'value'      => '$check_name$',
          'repeat_key' => false,
          'required'   => true,
        },
        '--username'       => {
          'value'      => '$icinga_api_username$',
          'repeat_key' => false,
          'required'   => true,
        },
        '--password'       => {
          'value'      => '$icinga_api_password$',
          'repeat_key' => false,
          'required'   => true,
        },
        # this check is expected to run locally on the icinga2 master, so
        # the default of localhost should be fine.
        '--host'           => {
          'value'      => '$icinga_fqdn$',
          'repeat_key' => false,
          'required'   => false,
        },
        # a service filter in the icinga2 filter format. E.g.:
        # '"role::elasticsearch::data" in host.groups && service.name == "disk"'
        '--service-filter' => {
          'value'      => '$icinga_service_filter$',
          'repeat_key' => false,
          'required'   => true,
        },
        # threshold with regards to the number of results from the service
        # filter above that are in the state indicated by --state. Should be
        # an integer.
        '--warn-threshold' => {
          'value'      => '$warn_threshold$',
          'repeat_key' => false,
          'required'   => false,
        },
        '--crit-threshold' => {
          'value'      => '$crit_threshold$',
          'repeat_key' => false,
          'required'   => false,
        },
        # state must be one of: ok, warning, critical, unknown
        '--state'          => {
          'value'      => '$check_state$',
          'repeat_key' => false,
          'required'   => true,
        },
        # order must be one of: min, max
        '--order'          => {
          'value'      => '$threshold_order$',
          'repeat_key' => false,
          'required'   => true,
        },
      },
    }

    icinga2::object::checkcommand { 'check-exit':
      command   => ['sudo', "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_exit.rb"],
      arguments => {
        '-r'           => {
          'value'      => '$run_command$',
          'repeat_key' => false,
          'required'   => true,
        },
        '--crit-level' => {
          'value'      => '$critical$',
          'repeat_key' => false,
          'required'   => false,
        },
        '--warn-level' => {
          'value'      => '$warning$',
          'repeat_key' => false,
          'required'   => false,
        },
      },
    }

    icinga2::object::checkcommand { 'check_ipmp':
      command   => ["${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_ipmp.py"],
      arguments => {
        '--minimum_links' => {
          'value'    => '$minimum_links$',
          'required' => false,
        },
      },
    }

    icinga2::object::checkcommand { 'check-jira-auth':
      command   => [
        "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_atlassian_auth.py",
      ],
      arguments => {
        '--url' => {
          'value'      => '$url$',
          'repeat_key' => false,
          'required'   => true,
        },
        '-U'    => {
          'value'      => '$username$',
          'repeat_key' => false,
          'required'   => true,
        },
        '-P'    => {
          'value'      => '$password$',
          'repeat_key' => false,
          'required'   => true,
        },
      },
    }

    icinga2::object::checkcommand { 'check_junos_int':
      command   => [ "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_junos_int.py" ],
      arguments => {
        '--hostname'  => {
          'value'      => '$hostname$',
          'repeat_key' => false,
          'required'   => true,
        },
        '--sshconfig' => {
          'value'      => '$ssh_config$',
          'repeat_key' => false,
          'required'   => false,
        },
        '--sshkey'    => {
          'value'      => '$sshkey$',
          'repeat_key' => false,
          'required'   => false,
        },
        '--user'      => {
          'value'      => '$user$',
          'repeat_key' => false,
          'required'   => false,
        },
      },
    }

    icinga2::object::checkcommand { 'check_leases':
      command   => ["${profile::monitoring::icinga2::common::plops_plugin_dir}/check_leases.py"],
      arguments => {
        '-w' => '$warning$',
        '-c' => '$critical$',
        '-f' => '$file$',
      },
    }

    icinga2::object::checkcommand { 'check_pdb_report_time':
      command   => ["${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_report_time.py"],
      arguments => {
        '--host'             => {
          'value'    => '$host$',
          'required' => true,
        },
        '--warn_minutes'     => {
          'value'    => '$warn_minutes$',
          'required' => false,
        },
        '--critical_minutes' => {
          'value'    => '$critical_minutes$',
          'required' => false,
        },
      },
    }

    icinga2::object::checkcommand { 'check-puppet-environments':
      command   => ['sudo', '-u', 'pe-puppet', "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_puppet_environments.py"],
      arguments => {
        '--path' => {
          'value'      => '$path$',
          'repeat_key' => false,
          'required'   => false,
        },
        '--warn' => {
          'value'      => '$warn$',
          'repeat_key' => false,
          'required'   => false,
        },
        '--crit' => {
          'value'      => '$crit$',
          'repeat_key' => false,
          'required'   => false,
        },
      },
    }

    icinga2::object::checkcommand { 'check-service-status':
      command   => ['sudo', "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_service_status.py"],
      arguments => {
        '--service' => {
          'value'      => '$service$',
          'repeat_key' => false,
          'required'   => true,
        },
      },
    }

    icinga2::object::checkcommand { 'check_ssl_cert':
      command   => ['sudo', "${::profile::monitoring::icinga2::common::plugin_dir}/check_ssl_cert"],
      arguments => {
        '--noauth'     => {
          'set_if'   => '$no_auth$',
        },
        '--host'       => {
          'value'    => '$host$',
          'required' => true,
        },
        '--warning'    => {
          'value'    => '$warning_days$',
          'required' => true,
        },
        '--critical'   => {
          'value'    => '$critical_days$',
          'required' => true,
        },
        '--file'       => {
          'value' => '$file$',
        },
        '--rootcert'   => {
          'value' => '$rootcert$',
        },
        '--selfsigned' => {
          'set_if' => '$self_signed$',
        },
      },
    }

    icinga2::object::checkcommand { 'cloudwatch':
      command   => ["${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_cloudwatch.py"],
      arguments => {
        '-n'                   => {
          # namespace for EC2 is 'AWS/EC2'
          'value'    => '$namespace$',
          'required' => true,
        },
        '-m'                   => {
          # metric is a cloudwatch metric name like "CPUCreditBalance"
          # or "NetworkIn"
          'value'    => '$metric$',
          'required' => true,
        },
        '-s'                   => {
          # sample_type must be one of
          # {Average,Sum,SampleCount,Maximum,Minimum}
          'value'    => '$sample_type$',
          'required' => false,
        },
        '-p'                   => {
          # integer time period in seconds
          'value'    => '$period$',
          'required' => false,
        },
        '-w'                   => {
          # warning if threshold is outside RANGE
          # example: "100:500" will warn if the metric is lower than 100
          # or greater than 500
          'value'    => '$warn_range$',
          'required' => false,
        },
        '-c'                   => {
          # go critical if threshold is outside RANGE
          # example: "100:500" will go critical if the metric is lower than 100
          # or greater than 500
          'value'    => '$crit_range$',
          'required' => false,
        },
        '-R'                   => {
          # should probably be set to 'us-west-2'
          'value'    => '$region$',
          'required' => false,
        },
        '-d'                   => {
          # select metric using additional dimension
          # common use case is "InstanceId=i-123456' to select metrics for
          # an EC2 instance with the ID of i-123456
          'value'    => '$dimension$',
          'required' => false,
        },
        '--delta'              => {
          # I think that this is a time offset from current time
          # for example to check metrics from 10 minutes ago
          # expressed in seconds
          'value'    => '$delta$',
          'required' => false,
        },
        # I think that divisors are used if you want to have relative
        # metrics, where the primary metric is divided by this one
        '--divisor-namespace'  => {
          'value'    => '$divisor_namespace$',
          'required' => false,
        },
        '--divisor-metric'     => {
          'value'    => '$divisor_metric$',
          'required' => false,
        },
        '--divisor-dimensions' => {
          'value'    => '$divisor_dimensions$',
          'required' => false,
        },
        '--divisor-statistic'  => {
          'value'    => '$divisor_statistic$',
          'required' => false,
        },
        '--divisor-delta'      => {
          'value'    => '$divisor_delta$',
          'required' => false,
        },
      },
    }

    icinga2::object::checkcommand { 'directory-freshness':
      command   => ["${profile::monitoring::icinga2::common::plops_plugin_dir}/check_directory_freshness.py"],
      arguments => {
        '--warning'   => '$warning$',
        '--critical'  => '$critical$',
        '-v'          => {
          'set_if' => '$verbose$',
        },
        '--directory' => {
          'value' => '$directory$',
        },
        '--exclude'   => {
          'value'      => '$exclude$',
          'repeat_key' => true,
        },
      },
    }

    icinga2::object::checkcommand { 'elasticsearch-query':
      command   => ["${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_elasticsearch_query.py"],
      arguments => {
        '--elasticsearch-host' => {
          'value'    => '$elasticsearch_host$',
          'required' => true,
        },
        '--index'              => {
          'value'    => '$index$',
          'required' => true,
        },
        '--lucene-query'       => {
          'value'    => '$lucene_query$',
          'required' => false,
        },
        '--agg-field'          => {
          'value'    => '$agg_field$',
          'required' => false,
        },
        '--agg-type'           => {
          'value'    => '$agg_type$',
          'required' => false,
        },
        '--agg-unit'           => {
          'value'    => '$agg_unit$',
          'required' => false,
        },
        '--agg-scale-factor'   => {
          'value'    => '$agg_scale_factor$',
          'required' => false,
        },
        '--use-index-pattern'  => {
          'value'    => '$use_index_pattern$',
          'required' => false,
        },
        '--interval'           => {
          'value'    => '$interval$',
          'required' => false,
        },
        '--time-field'         => {
          'value'    => '$time_field$',
          'required' => false,
        },
        '-w'                   => {
          'value'    => '$warning$',
          'required' => false,
        },
        '-c'                   => {
          'value'    => '$critical$',
          'required' => false,
        },
      },
    }

    icinga2::object::checkcommand { 'forge_dl':
      command   => [ "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_forge_dl.py" ],
    }

    icinga2::object::checkcommand { 'graphite-metric':
      command   => ["${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_graphite"],
      arguments => {
        '--url'           => '$url$',
        '--metric'        => '$metric$',
        '--shortname'     => '$shortname$',
        '--duration'      => '$duration$',
        '--function'      => '$function$',
        '--warning'       => '$warning$',
        '--critical'      => '$critical$',
        '--units'         => '$units$',
        '--message'       => '$message$',
        '--zero-on-error' => '$zero_on_error$',
      },
    }

    icinga2::object::checkcommand { 'haproxy_backend_count':
      command   => [ '/usr/local/bin/haproxy_check' ],
      # The Erlang VM needs to have a HOME directory set and Icinga2 does not exec child processes with this environment variable because it generally isn't used for anything.
      env       => {
        'HOME' => '/tmp',
      },
      arguments => {
        # check name will be prepended to check output; use something short
        # this should usually be set the same as the backend name, because it's
        # the only context somebody being paged will see
        '--name'           => {
          'value'      => '$name$',
          'repeat_key' => false,
          'required'   => true,
        },
        # warn if more than this many backend hosts are down
        # should be lower than the critical threshold
        '--warn-threshold' => {
          'value'      => '$warn_threshold$',
          'repeat_key' => false,
          'required'   => false,
        },
        # go critical if more than this many backend hosts are down
        # should be higher than the warn threshold
        '--crit-threshold' => {
          'value'      => '$crit_threshold$',
          'repeat_key' => false,
          'required'   => false,
        },
        # backend name
        '--backend'        => {
          'value'      => '$backend$',
          'repeat_key' => false,
          'required'   => true,
        },
      },
    }

    icinga2::object::checkcommand { 'locate-station':
      command   => ["${::profile::monitoring::icinga2::common::plops_plugin_dir}/locate_station.py"],
      arguments => {
        '--xms-host'      => {
          'value'      => '$xms_host$',
          'required'   => true,
          'repeat_key' => false,
        },
        '-u'              => {
          'value'      => '$xms_user$',
          'required'   => true,
          'repeat_key' => false,
        },
        '-p'              => {
          'value'      => '$xms_password$',
          'required'   => true,
          'repeat_key' => false,
        },
        '--station-mac'   => {
          'value'      => '$station_mac$',
          'required'   => true,
          'repeat_key' => false,
        },
        '--station-alias' => {
          'value'      => '$station_alias$',
          'required'   => true,
          'repeat_key' => false,
        },
      },
    }

    icinga2::object::checkcommand { 'meminfo':
      command   => ["${profile::monitoring::icinga2::common::plops_plugin_dir}/check_meminfo.pl"],
      arguments => {
        '-k'    => '$meminfo_keys$',
      },
    }

    icinga2::object::checkcommand { 'openldap_cluster':
      command   => [ "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_ldap_cluster.py" ],
      arguments => {
        '--basedn' => {
          'value'      => '$basedn$',
          'repeat_key' => false,
          'required'   => true,
        },
        '--binddn' => {
          'value'      => '$binddn$',
          'repeat_key' => false,
          'required'   => true,
        },
        '--bindpw' => {
          'value'      => '$bindpw$',
          'repeat_key' => false,
          'required'   => true,
        },
        '--nodes'  => {
          'value'      => '$nodes$',
          'repeat_key' => false,
          'required'   => true,
        },
      },
    }

    icinga2::object::checkcommand { 'pgpool':
      command   => ["${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_pgpool.pl"],
      arguments => {
        '-d' => {
          'value' => '$path$',
        },
        '-H' => {
          'value' => '$host$',
        },
        '-P' => {
          'value' => '$port$',
        },
        '-U' => {
          'value' => '$user$',
        },
        '-W' => {
          'value' => '$password$',
        },
      },
    }

    icinga2::object::checkcommand { 'postgres':
      command   => ["${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_postgres.pl"],
      arguments => {
        '--action' => {
          'value'      => '$action$',
          'repeat_key' => false,
          'required'   => true,
        },
        '--host'   => {
          'value'      => '$hosts$',
          'repeat_key' => true,
          'required'   => false,
        },
        '--dbuser' => {
          'value'      => '$db_user$',
          'repeat_key' => false,
          'required'   => false,
        },
        '--dbpass' => {
          'value'      => '$db_pass$',
          'repeat_key' => false,
          'required'   => false,
        },
        '--dbname' => {
          'value'      => '$db_name$',
          'repeat_key' => false,
          'required'   => false,
        },
        '-w'       => {
          'value'      => '$warning$',
          'repeat_key' => false,
          'required'   => false,
        },
        '-c'       => {
          'value'      => '$critical$',
          'repeat_key' => false,
          'required'   => false,
        },
      },
    }

    icinga2::object::checkcommand { 'postgres_sudo':
      command   => ['sudo', '-u', 'postgres', "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_postgres.pl"],
      arguments => {
        '--action' => {
          'value'      => '$action$',
          'repeat_key' => false,
          'required'   => true,
        },
        '--host'   => {
          'value'      => '$hosts$',
          'repeat_key' => true,
          'required'   => false,
        },
        '--dbuser' => {
          'value'      => '$db_user$',
          'repeat_key' => false,
          'required'   => false,
        },
        '--dbpass' => {
          'value'      => '$db_pass$',
          'repeat_key' => false,
          'required'   => false,
        },
        '--dbname' => {
          'value'      => '$db_name$',
          'repeat_key' => false,
          'required'   => false,
        },
        '-w'       => {
          'value'      => '$warning$',
          'repeat_key' => false,
          'required'   => false,
        },
        '-c'       => {
          'value'      => '$critical$',
          'repeat_key' => false,
          'required'   => false,
        },
      },
    }

    $puppet_agent_base_command = [
      'sudo',
      "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_puppet_agent.py",
      '--check-type',
    ]

    # We leave this in place so as to not break icinga before everything switches over.
    icinga2::object::checkcommand { 'puppet-agent':
      command => $puppet_agent_base_command << 'agent_disabled',
    }

    icinga2::object::checkcommand { 'puppet-agent-agent_disabled':
      command => $puppet_agent_base_command << 'agent_disabled',
    }

    icinga2::object::checkcommand { 'puppet-agent-last_run_time':
      command   => $puppet_agent_base_command << 'last_run_time',
      arguments => {
        '--wm' => {
          'value'      => '$warn_minutes$',
          'repeat_key' => false,
          'required'   => false,
        },
        '--cm' => {
          'value'      => '$crit_minutes$',
          'repeat_key' => false,
          'required'   => false,
        },
      },
    }

    icinga2::object::checkcommand { 'puppet-agent-last_run_status':
      command  => $puppet_agent_base_command << 'last_run_status',
    }

    icinga2::object::checkcommand { 'puppet-agent-environment':
      command  => $puppet_agent_base_command << 'environment',
    }

    icinga2::object::checkcommand { 'ro-disks':
      command => ["${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_ro_disks.sh"],
    }

    icinga2::object::checkcommand { 'ucs':
      command   => ["${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_ucs"],
      arguments => {
        '-H' => '$host$',
        '-T' => '$test$',
        '-N' => '$object_name$',
        '-C' => '$community_string$',
      },
    }

    icinga2::object::checkcommand { 'vcenter':
      command   => ["${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_vcenter.rb"],
      arguments => {
        '-u' => {
          'value' => '$user$',
        },
        '-p' => {
          'value' => '$password$',
        },
        '-h' => {
          'value' => '$host$',
        },
        '-i' => {
          'value' => '$instance_uuid$',
        },
      },
    }

    icinga2::object::checkcommand { 'vmpooler':
      command   => ["${profile::monitoring::icinga2::common::plops_plugin_dir}/check_vmpooler.rb"],
      arguments => {
        '--url' => '$url$',
        '-w'    => '$warning$',
        '-c'    => '$critical$',
      },
    }

    icinga2::object::checkcommand { 'check-jenkins':
      command => ['sudo', "${profile::monitoring::icinga2::common::plops_plugin_dir}/check_jenkins.py"],
    }

    icinga2::object::checkcommand { 'mesos':
      command   => ["${profile::monitoring::icinga2::common::plops_plugin_dir}/check_mesos.py"],
      arguments => {
        '--host'      => {
          'value'    => '$host$',
          'required' => true,
        },
        '--framework' => {
          'set_if' => '$set_framework$',
          'value'  => '$framework$',
        },
      },
    }

    icinga2::object::checkcommand { 'zookeeper_status':
      command   => ["${profile::monitoring::icinga2::common::plops_plugin_dir}/check_zookeeper_status.py"],
      arguments => {
        '--zk-host' => '$zk_host$',
      },
    }

    icinga2::object::checkcommand { 'abs_frontend':
      command   => ["${profile::monitoring::icinga2::common::plops_plugin_dir}/check_abs_frontend.py"],
      arguments => {
        '--abs-host' => '$abs_host$',
        '--timeout'  => '$timeout$',
      },
    }

    icinga2::object::checkcommand { 'cith_api':
      command   => ["${profile::monitoring::icinga2::common::plops_plugin_dir}/check_cith_api.py"],
      arguments => {
        '--cith-api-host' => '$cith_api_host$',
        '--timeout'       => '$timeout$',
      },
    }

    icinga2::object::checkcommand { 'cith_ui':
      command   => ["${profile::monitoring::icinga2::common::plops_plugin_dir}/check_cith_ui.py"],
      arguments => {
        '--cith-ui-host' => '$cith_ui_host$',
        '--timeout'      => '$timeout$',
      },
    }

    icinga2::object::checkcommand { 'check_docker_datafile':
      command   => ['sudo', "${profile::monitoring::icinga2::common::plops_plugin_dir}/check_docker_datafile.py"],
      arguments => {
        '--datafile'      => '$datafile$',
        '--warn_free'     => '$warn_free$',
        '--critical_free' => '$critical_free$',
      },
    }

    icinga2::object::checkcommand { 'check_docker_thinpool':
      command   => ['sudo', "${profile::monitoring::icinga2::common::plops_plugin_dir}/check_docker_thinpool.py"],
      arguments => {
        '--thinpool'      => '$thinpool$',
        '--warn_free'     => '$warn_free$',
        '--critical_free' => '$critical_free$',
      },
    }

    # Event commands run before notification, used to try to fix problems
    # easily, such as service restarts
    icinga2::object::eventcommand { 'restart_service':
      command   => ['sudo', "${profile::monitoring::icinga2::common::plops_plugin_dir}/restart_service.sh"],
      arguments => {
        '-s' => {
          'value'    => '$restart_service_name$',
          'required' => true,
        },
        '-i' => {
          'value'    => '$service.state_id$',
          'required' => true,
        },
        '-x' => {
          # We only check for 'systemd', otherwise we assume init.d is used
          'value'    => '$init_system$',
          'required' => true,
        },
      },
    }

    icinga2::object::eventcommand { 'reset_docker_thinpool':
      command   => ["${profile::monitoring::icinga2::common::plops_plugin_dir}/reset_docker_thinpool_job.sh"],
      arguments => {
        '-m' => '$mesosmaster$',
        '-a' => '$mesosagent$',
        '-t' => unwrap(lookup('profile::monitoring::icinga2::plugins::sensitive_reset_docker_thinpool_api_token')),
      },
    }

    icinga2::object::checkcommand { 'check_marathon_application':
      command   => ["${profile::monitoring::icinga2::common::plops_plugin_dir}/check_marathon_application.py"],
      arguments => {
        '--application'  => '$application$',
        '--marathon-url' => '$marathon_url$',
        '--instances'    => '$instances$',
      },
    }
  }
}
