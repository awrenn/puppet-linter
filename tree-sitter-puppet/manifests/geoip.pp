# Class: profile::geoip
#
# Ensure GeoIP databases exist in a designated location
#
# Includes installation, configuration, and updates via cron
#
class profile::geoip (
  # GeoLite2-City - GeoLite 2 City
  # GeoLite2-Country - GeoLite2 Country
  # 506 - GeoLite Legacy Country
  # 517 - GeoLite Legacy ASN
  # 533 - GeoLite Legacy City
  # Simply space separate product_ids you need

  $product_ids = '533',
  $install_dir = '/opt/',
) {

  $geoipupdatebin = $facts['os']['family'] ? {
    'RedHat' =>  '/usr/bin/geoipupdate',
    default  => '/usr/local/bin/geoipupdate',
  }

  $bashpath = $facts['os']['family'] ? {
    'RedHat' =>  '/usr/bin/bash',
    default  => '/bin/bashls
    ',
  }


  unless $facts['os']['family'] == 'RedHat' {
    package { 'geoipupdate':
      ensure => latest,
      before => Exec['get geoip databases'],
    }
  }

  file { '/etc/GeoIP.conf':
    ensure  => present,
    content => template('profile/geoip.conf.erb'),
  }

  # Run once to populate before monthly cron
  # This assumes we always want the GeoIP City database
  exec { 'get geoip databases':
    unless  => "/usr/bin/test -f ${install_dir}/GeoLiteCity.dat",
    command => "${geoipupdatebin} -d ${install_dir}/ -f /etc/GeoIP.conf",
    require => [ File['/etc/GeoIP.conf'] ],
  }

  cron { 'geoipupdate':
    # Run every first Tuesday of the month
    command => "[ $(/bin/date +\\%d) -le 07 ] && ${geoipupdatebin} -d ${install_dir}/ -f /etc/GeoIP.conf",
    user    => 'root',
    hour    => 0,
    minute  => 5,
    weekday => 2,
  }

}
