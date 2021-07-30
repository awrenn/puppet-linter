class profile::meat {

  include supervisord

  supervisord::program { 'meat':
    command     => '/usr/local/bin/node /usr/local/bin/meat',
    priority    => '100',
    autorestart => 'true',
    autostart   => true,
    user        => 'root',
    environment => {
      'MEAT_HOME' => '/usr/local/lib/node_modules/meat',
    },
  }
}
