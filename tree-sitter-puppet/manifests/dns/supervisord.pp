# Class used to manage supervisord
# on a dns node to keep route in
# ospf if bind is resolving

class profile::dns::supervisord {

  include supervisord

  file { '/opt/ospf_check.sh':
    source => 'puppet:///modules/profile/supervisord/ospf_check.sh',
    mode   => '0744',
    owner  => 'root',
  }

  supervisord::program { 'ospf_check':
    command     => '/opt/ospf_check.sh',
    priority    => '100',
    autorestart => 'true',
    autostart   => true,
    user        => 'root',
    require     => File['/opt/ospf_check.sh'],
  }

}
