class profile::metrics::diamond::client(
  $path_prefix = undef,
  $rotate_days = 7
) {

  require ::profile::metrics::diamond::collectors
  require ::profile::metrics

  $collector_path = '/usr/share/diamond/collectors'
  $temp_prefix = inline_template("<%= @fqdn.split('.').reverse.join(' ') %>")
  if $path_prefix != undef {
    $graphite_prefix = $path_prefix

    # When given a path prefix, do not append a hostname
    $graphite_hostname = ''
  }
  else {
    $graphite_prefix = "${inline_template("<%= @temp_prefix.split.take(@temp_prefix.split.size-1).join('.') %>")}"
    $graphite_hostname = undef
  }
  $graphite_server = hiera('graphite::server')
  $install_from_pip = hiera('profile::metrics::diamond::client::install_from_pip', false)
  $interval = hiera('profile::metrics::diamond::client::interval', 60)

  # Need to avoid accidentally ending up with psutil==4.4.2 because it's borked
  # and will bork all Collectors that use it.  CentOS Seems to install pip as a 
  # dependency via Yum, whereas other OS' do not, therefor skip updating psutil 
  # for the reasons above if the operatingsystem is CentOS
  unless ($facts['os']['name'] == 'CentOS') or ($facts['os']['name'] == 'Solaris') {
    package { 'psutil':
      ensure   => '5.0.1',
      provider => pip,
      before   => Class['diamond'],
      require  => Package['gcc'],
    }
  }

  if $facts['kernel'] == 'Linux' {
    # Rotation job for pip logs (grows quickly)
    logrotate::job { 'diamond-pip':
      log     => '/tmp/pip.log',
      options => [
        'maxsize 100M',
        'rotate 3',
        'weekly',
        'compress',
        'compresscmd /usr/bin/xz',
        'uncompresscmd /usr/bin/unxz',
        'compressext .xz',
        'missingok',
        'notifempty',
        'su root root',
        'create 0644 root root',
      ],
    }
  }


  ensure_packages(['gcc'])

  class { 'diamond':
    graphite_host    => $graphite_server,
    path_prefix      => "stats.${graphite_prefix}",
    server_hostname  => $graphite_hostname,
    graphite_handler => 'graphite.GraphiteHandler',
    interval         => $interval,
    version          => hiera('profile::metrics::diamond::client::version'),
    purge_collectors => true,
    install_from_pip => $install_from_pip,
    rotate_days      => $rotate_days,
  }
  Diamond::Collector <| tag == 'default' |>
}
