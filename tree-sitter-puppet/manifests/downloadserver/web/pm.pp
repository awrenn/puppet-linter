# This profile creates the 'pm' (Puppet Enterprise Downloads) and associated resources.
class profile::downloadserver::web::pm {

  file { '/opt/pm':
    ensure  => directory,
    owner   => root,
    group   => enterprise,
    mode    => '0664',
    recurse => false,
  }

  file { '/opt/pm/.htaccess':
    ensure => absent,
  }

  a2mod { 'cgid': ensure => present, }

  file { '/usr/lib/cgi-bin/download.cgi':
    ensure => file,
    owner  => root,
    group  => enterprise,
    mode   => '0755',
    source => 'puppet:///modules/profile/downloadserver/web/pm/pe_download.cgi',
  }

  file { '/usr/lib/cgi-bin/vm_download.cgi':
    ensure => file,
    owner  => root,
    group  => enterprise,
    mode   => '0755',
    source => 'puppet:///modules/profile/downloadserver/web/pm/vm_download.cgi',
  }

  file { '/usr/lib/cgi-bin/pdk_download.cgi':
    ensure => file,
    owner  => root,
    group  => enterprise,
    mode   => '0755',
    source => 'puppet:///modules/profile/downloadserver/web/pm/pdk_download.cgi',
  }

  file { '/usr/lib/cgi-bin/beta_download.cgi':
    ensure => 'file',
    owner  => 'root',
    group  => 'enterprise',
    mode   => '0755',
    source => 'puppet:///modules/profile/downloadserver/web/pm/beta_download.cgi',
  }

  apache::vhost { 'pm.puppetlabs.com':
    servername => 'pm.puppetlabs.com',
    port       => 80,
    docroot    => '/opt/pm',
    ssl        => false,
    auth       => false,
    priority   => 16,
    template   => 'profile/downloadserver/web/pm/vhost_with_cgi_and_s3proxy.conf.erb';
  }

  cron { '/opt/pm owners and perms':
    command => '/bin/chown -R root:enterprise /opt/pm 1> /dev/null; /bin/chmod -R ug+Xwr /opt/pm 1> /dev/null',
    user    => root,
    hour    => '*',
    minute  => '*/30',
  }

}
