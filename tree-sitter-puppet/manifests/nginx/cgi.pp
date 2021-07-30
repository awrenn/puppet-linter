# Support CGI via FastCGI in NGINX
#
# $description - This will be used for the service and socket descriptions,
#   with " FastCGI service" and " FastCGI socket" appended, respectively.
# $user - you SHOULD create a new service user to run FastCGI. By default, it
#   runs as the web server, which may give it access to web server internals
#   if the CGI script is compromised.
define profile::nginx::cgi (
  String[1] $description = $title,
  String[1] $http_user = 'www-data',
  String[1] $http_group = $http_user,
  String[1] $user = 'www-data',
  String[1] $group = $user,
) {
  package { 'fcgiwrap':
    ensure => installed,
  }

  # Disable default fcgiwrap services
  service { ['fcgiwrap.socket', 'fcgiwrap.service']:
    ensure  => stopped,
    enable  => false,
    require => Package['fcgiwrap'],
  }

  $socket = "/run/fastcgi-${title}.sock"
  file {
    default:
      ensure => file,
      owner  => 'root',
      group  => '0',
      mode   => '0444',
      notify => [
        Exec['puppetlabs-modules systemctl daemon-reload'],
        Service["fastcgi-${title}.socket"],
      ],
    ;
    "/etc/systemd/system/fastcgi-${title}.service":
      content => epp('profile/nginx/cgi/systemd.service.epp', {
        title       => $title,
        description => $description,
        user        => $user,
        group       => $group,
        exec        => '/usr/sbin/fcgiwrap',
      }),
    ;
    "/etc/systemd/system/fastcgi-${title}.socket":
      content => epp('profile/nginx/cgi/systemd.socket.epp', {
        title       => $title,
        description => $description,
        http_user   => $http_user,
        http_group  => $http_group,
        socket      => $socket,
      }),
    ;
  }

  service { "fastcgi-${title}.socket":
    ensure     => running,
    enable     => true,
    hasrestart => true,
    subscribe  => Package['fcgiwrap'],
  }

  nginx::resource::upstream { $title:
    members => {
      "unix:${socket}" => {
        server => "unix:${socket}",
      },
    },
  }
}
