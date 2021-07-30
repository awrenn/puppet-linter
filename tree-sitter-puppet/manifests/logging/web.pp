class profile::logging::web {


  include profile::nginx
  package { 'git':
    ensure => present,
  }

  $es_host = hiera('profile::elasticsearch::common::url', "${ipaddress}:9200")
  nginx::resource::server { 'kibana3.ops.puppetlabs.net':
    server_name => ['kibana3.ops.puppetlabs.net'],
    ssl         => false,
    www_root    => '/opt/kibana/src',
  }

  nginx::resource::server { 'kibana.ops.puppetlabs.net':
    listen_options => 'default_server',
    server_name    => ['kibana.ops.puppetlabs.net'],
    ssl            => false,
    proxy          => 'http://kibana4_server',
  }

  nginx::resource::upstream { 'kibana4_server':
    members => {
      '127.0.0.1:5601' => {
        server => '127.0.0.1',
        port   => 5601,
      },
    },
  }

  vcsrepo { '/opt/kibana':
    ensure   => present,
    provider => git,
    source   => 'git://github.com/elasticsearch/kibana.git',
    revision => 'v3.1.0',
    before   => File['/opt/kibana/src/config.js'],
  }

  file { '/opt/kibana/src/config.js':
    content =>  template('profile/kibana/config.js.erb'),
    owner   => 'www-data',
    group   => 'www-data',
  }

  file { '/opt/kibana/src/app/dashboards/metrics-proj.js':
    ensure => present,
    source => 'puppet:///modules/profile/logging/web/metrics-proj.js',
    owner  => 'www-data',
    group  => 'www-data',
  }

  @@haproxy::balancermember { "${facts['networking']['fqdn']}-kibana_${facts['classification']['stage']}":
    listening_service => "logstash-kibana_${facts['classification']['stage']}",
    server_names      => $facts['networking']['hostname'],
    ipaddresses       => $facts['networking']['ip'],
    ports             => '80',
    options           => 'check',
  }

  class { 'kibana4':
    version           => '4.1.0-linux-x64',
    port              => '5601',
    host              => '127.0.0.1',
    elasticsearch_url => "http://${es_host}",
  }
}
