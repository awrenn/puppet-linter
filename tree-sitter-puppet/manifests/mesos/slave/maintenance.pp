# Configure mesosagent nodes to permit jenkins access for maintenance
class profile::mesos::slave::maintenance (
  String $user = 'jenkins',
  String $user_home = '/var/lib/jenkins',
  String $key_file = 'id_rsa_mesos_maintenance'
) {

  ssh::allowgroup { $user: }

  sudo::entry { "${user}_mesos_maintenance":
    entry => join([
      "${user} ALL=(ALL) NOPASSWD:/usr/bin/systemctl",
      '/usr/sbin/shutdown',
      '/usr/bin/rm',
      '/usr/sbin/lvremove',
      '/usr/local/bin/puppet',
    ], ', '),
  }

  ssh::key { $user:
    key_path           => "${user_home}/.ssh/${key_file}",
    target_query       => 'Class[Role::Cinext::Mesosagent]',
    manage_known_hosts => false,
  }

  ssh::key::collector { $user:
    options => [
      'no-X11-forwarding',
      'no-port-forwarding',
      'no-pty',
    ],
  }
}
