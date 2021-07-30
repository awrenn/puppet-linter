class profile::nexpose::scanengine {

  class { 'nexpose':
    component_type => 'engine',
    first_name     => 'Puppet',
    last_name      => 'Inc',
    company_name   => 'Puppet Inc',
    installer_uri  => 'https://download2.rapid7.com/download/InsightVM/Rapid7Setup-Linux64.bin',
  }
}
