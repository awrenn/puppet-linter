# This profile creates a base vhost based on the server fqdn and ensures it has no index.
class profile::downloadserver::web::base {

  file { '/var/www/index.html':
    ensure => absent,
  }

  apache::vhost { $fqdn:
    port     => 80,
    options  => 'None',
    docroot  => '/var/www',
    template => 'profile/downloadserver/web/vhost.conf.erb',
  }
}
