# An application run through Unicorn and NGINX
#
# In NGINX this only creates an upstream object called "unicorn_${name}"; it
# does not create a vhost.
define profile::unicorn::app (
  Pattern[/^\/./] $path,
  String[1] $user = $name,
  String[1] $group = $name,
  Variant[Enum[system, bundler], Pattern[/[a-z]/]] $source = system,
) {
  include profile::unicorn

  $config_path = "${::profile::unicorn::config_dir}/${name}_config.rb"
  $pid_path = "/var/run/unicorn_${name}.pid"
  $log_dir = "/var/log/unicorn_${name}"
  $socket_path = "/var/run/unicorn_${name}.sock"
  $socket = "unix:${socket_path}"

  nginx::resource::upstream { "unicorn_${name}":
    members     => {
      "${socket}" => {
        server       => $socket,
        fail_timeout => '0',
      },
    },
    cfg_prepend => {
      'keepalive' => '10',
    },
  }

  file { $log_dir:
    ensure => directory,
    mode   => '0755',
    owner  => $user,
    group  => $group,
    before => Unicorn::App[$name],
  }

  logrotate::job { "unicorn_${name}":
    log        => "${log_dir}/*.log",
    options    => [
      'rotate 30',
      'daily',
      'compress',
      'notifempty',
      'sharedscripts',
    ],
    postrotate => "f=${pid_path} ; test -s \$f && kill -USR1 $(cat \$f)",
  }

  unicorn::app { $name:
    approot     => $path,
    source      => $source,
    config_file => $config_path,
    logdir      => $log_dir,
    pidfile     => $pid_path,
    socket      => $socket_path,
    user        => $user,
    group       => $group,
    preload_app => true,
  }
}
