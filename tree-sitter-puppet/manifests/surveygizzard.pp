class profile::surveygizzard (
  $hostname                   = $facts['networking']['fqdn'],
  $db_password                = false,
  $db_username                = false,
  $db_host                    = false,
  $db_name                    = false,
  $gh_username                = false,
  $gh_password                = false,
) {
  $application = 'surveygizzard'
  $docroot = '/var/www/surveyreports'

  include profile::server::params
  include profile::fw::http
  include profile::nginx
  include ruby::dev

  class { '::rack':
    ensure => '1.6.8',
    }

  package { 'postgresql-devel':
      ensure => installed,
  }

  package {
    default:
      provider => gem,
      notify   => Profile::Unicorn::App[$app_name],
      ;
    # pushing sinatra to a version compatible with rack 1.6.8
    'sinatra':
      ensure  => '1.4.6',
      require => Package['rack'],
      ;
    'public_suffix':
      ensure => '2.0.5',
      ;
    'mustermann':
      ensure => '0.3.1',
      ;
    'education_dashboard':
      ensure  => latest,
      source  => 'https://artifactory.delivery.puppetlabs.net/artifactory/api/gems/rubygems/',
      require => Package['rack', 'postgresql-devel'],
      ;
  }

  # Redirect all requests to hosts not matching $hostname to https://$hostname
  nginx::resource::server { 'default':
    listen_options       => 'default',
    server_name          => [ '-' ],
    use_default_location => false,
    raw_append           => "\n  return 301 http://${hostname}\$uri\$is_args\$args;",
  }

  # Proxy https://$hostname (and only that)
  nginx::resource::server { $hostname:
    proxy => 'http://unicorn',
    spdy  => 'on',
  }

  $unicorn_socket = '/opt/surveyreports/unicorn.sock'
  $unicorn_pidfile = '/opt/surveyreports/unicorn.pid'

  $socket = "unix:${unicorn_socket}"

  nginx::resource::upstream { 'unicorn':
    members     =>  {
                        "${socket}" => {
                          server       => $socket,
                          fail_timeout => '0',
                        },
    },
    cfg_prepend => {
      'keepalive' => '10',
    },
  }

  unicorn::app { 'surveyreports':
    approot         => '/opt/surveyreports',
    config_file     => '/etc/unicorn_surveyreports.rb',
    config_template => 'profile/surveygizzard/unicorn_surveyreports.rb.erb',
    logdir          => '/var/log/surveyreports',
    pidfile         => $unicorn_pidfile,
    socket          => $unicorn_socket,
    user            => 'surveygizzard',
    group           => 'surveygizzard',
    preload_app     => true,
    require         => [File['/etc/.reporterc'], Class['::ruby::dev']],
  }

  logrotate::job { 'surveyreports':
    log        => '/var/log/surveyreports/*.log',
    options    => [
      'rotate 30',
      'daily',
      'compress',
      'notifempty',
      'sharedscripts',
    ],
    postrotate => "f=${unicorn_pidfile} ; test -s \$f && kill -USR1 $(cat \$f)",
  }

  Account::User <| title == 'surveygizzard' |>
  Account::User <| groups == 'education' or groups == 'education-admins' or groups == 'prosvc' |>
  ssh::allowgroup { ['education', 'prosvc']: }
  sudo::allowgroup { 'education-admins': }

  file { ['/opt/surveyreports', '/var/log/surveyreports']:
    ensure => directory,
    mode   => '0755',
    owner  => 'surveygizzard',
    group  => 'surveygizzard',
  }



  file { '/opt/surveyreports/config.ru':
    ensure => 'file',
    owner  => $application,
    group  => $application,
    mode   => '0640',
    source => 'puppet:///modules/profile/surveygizzard/config.ru',
  }

  file { '/etc/.reporterc':
    ensure  => 'file',
    content => epp('profile/surveygizzard/reporterc',
                  {
                    'db_password' => $profile::surveygizzard::db_password,
                    'db_username' => $profile::surveygizzard::db_username,
                    'db_host'     => $profile::surveygizzard::db_host,
                    'db_name'     => $profile::surveygizzard::db_name,
                    'gh_username' => $profile::surveygizzard::gh_username,
                    'gh_password' => $profile::surveygizzard::gh_password}),
    owner   => 'surveygizzard',
    group   => 'surveygizzard',
    mode    => '0640',
  }

}
