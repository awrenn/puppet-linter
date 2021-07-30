# Configure the Cinder block storage service to work with our Tintri
#
# This can only be used on a host with the block storage role in Platform9. The
# block storage must be set up in the Platform9 UI using the default path.
#
# See profile::p9openstack::compute for instructions on setting up the Tintri.
class profile::p9openstack::cinder (
  String[1] $tintri_hostname,
  String[1] $tintri_mountpoint,
  String[1] $tintri_username,
  String[1] $tintri_password,
  String[1] $debug,
) {
  file {
    default:
      ensure => directory,
      owner  => 'pf9',
      group  => 'pf9group',
      mode   => '0755',
    ;
    '/etc/cinder': ;
    '/etc/cinder/nfs_shares':
      ensure  => file,
      mode    => '0444',
      content => @("END"),
        ${tintri_hostname}:/tintri/${tintri_mountpoint}
        | END
    ;
    '/opt/pf9/etc/pf9-cindervolume-base': ;
    '/opt/pf9/etc/pf9-cindervolume-base/conf.d': ;
    '/opt/pf9/etc/pf9-cindervolume-base/conf.d/cinder_override.conf':
      ensure  => file,
      mode    => '0440',
      content => epp('profile/p9openstack/cinder/cinder_override.conf.epp', {
        hostname => $tintri_hostname,
        username => $tintri_username,
        password => $tintri_password,
        debug    => $debug,
      }),
      notify  => Service['pf9-cindervolume-base'],
    ;
    '/opt/pf9/pf9-cindervolume-base/lib/python3.6/site-packages/cinder/volume/drivers/tintri.py':
      ensure  => file,
      mode    => '0644',
      source  => 'https://artifactory.delivery.puppetlabs.net/artifactory/generic__local/infracore/platform9/tintri.py',
      require => Exec['install platform9'],
      notify  => Service['pf9-cindervolume-base'],
  }

  ##INFC-18479 Make Platform 9 Glance Images publicable by anyone.
  service { 'pf9-glance-api':
    ensure    => running,
    enable    => true,
    start     => '/etc/init.d/pf9-glance-api start',
    stop      => '/etc/init.d/pf9-glance-api stop',
    status    => '/etc/init.d/pf9-glance-api status',
    subscribe => Exec['install platform9'],
  }

  augeas { 'glance_set_publicize_image':
    lens    => 'Json.lns',
    incl    => '/etc/glance/policy.json',
    changes => [
      'set /files/etc/glance/policy.json/dict/entry[.="publicize_image"]/string ""',
    ],
    notify  => Service['pf9-glance-api'],
  }

  service { 'pf9-cindervolume-base':
    ensure    => running,
    enable    => true,
    subscribe => Exec['install platform9'],
  }
}
