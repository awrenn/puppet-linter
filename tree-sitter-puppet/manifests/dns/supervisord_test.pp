# Class used to manage supervisord
# on a dns node to keep route in
# ospf if bind is resolving

class profile::dns::supervisord_test {

  include supervisord

  file { '/opt/ospf_check_test.sh':
    path   => '/opt/ospf_check.sh',
    source => 'puppet:///modules/profile/supervisord/ospf_check_test.sh',
    mode   => '0744',
    owner  => 'root',
  }

  supervisord::program { 'ospf_check':
    command     => '/opt/ospf_check.sh',
    priority    => '100',
    autorestart => 'true',
    autostart   => true,
    user        => 'root',
    require     => File['/opt/ospf_check_test.sh'],
  }

}
