# Manages installation and configuration of Google Cloud SQL Proxy
#
class profile::cloud_sql_proxy (
  String[1] $creds_file_content,
  String[1] $creds_file_name,
  String[1] $instance_id,
  String    $additional_options = '',
  String[1] $configdir          = '/etc/cloudsql/',
  Integer   $local_port         = 5432,
) {

  file { $configdir:
    ensure => directory,
    mode   => '0750',
    owner  => 'root',
    group  => 'root',
  }

  file { "${configdir}cloudsql.conf":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('profile/cloud_sql_proxy/cloudsql.conf.erb'),
    require => File[$configdir],
  }

  file { "${configdir}${creds_file_name}":
    ensure    => file,
    owner     => 'root',
    group     => 'root',
    mode      => '0750',
    show_diff => false,
    content   => $creds_file_content,
    require   => File[$configdir],
    notify    => Service['cloudsql'],
  }

  if $facts['systemd'] {
    file { '/lib/systemd/system/cloudsql.service':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => template('profile/cloud_sql_proxy/cloudsql.service.erb'),
      notify  => Service['cloudsql'],
    }
  }
  else {
    file { '/etc/init.d/cloudsql':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => template('profile/cloud_sql_proxy/cloudsql.erb'),
      notify  => Service['cloudsql'],
    }
  }

  wget::fetch { 'https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64':
    destination => '/usr/local/bin/cloud_sql_proxy',
    cache_dir   => $facts['puppet_vardir'],
    redownload  => false,
    mode        => '0755',
    before      => Service['cloudsql'],
  }

  if $facts['systemd'] {
    service { 'cloudsql':
      ensure     => running,
      enable     => true,
      hasrestart => false,
      hasstatus  => false,
      subscribe  => File['/lib/systemd/system/cloudsql.service', "${configdir}${creds_file_name}"],
    }
  }
  else {
    service { 'cloudsql':
      ensure     => running,
      path       => '/etc/init.d',
      hasstatus  => false,
      hasrestart => false,
      subscribe  => File["${configdir}cloudsql.conf", "${configdir}${creds_file_name}"],
    }
  }

}
