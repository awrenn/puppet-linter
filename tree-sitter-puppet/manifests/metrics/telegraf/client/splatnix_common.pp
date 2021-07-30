# Telegraf configs common to Splatnix nodes
class profile::metrics::telegraf::client::splatnix_common (
  Optional[Array[String[1]]] $additional_interfaces = undef,
){
  $_default_interfaces = ['eth*', 'enp0s[0-1]', 'ens192']

  if $additional_interfaces {
    $_interfaces = $additional_interfaces + $_default_interfaces
  } else {
    $_interfaces = $_default_interfaces
  }

  telegraf::input {
    default:
      options => [{
        'interval' => '15s',
      }],
    ;
    'diskio': ;
    'mem': ;
    'net':
      options => [{
        'interval'              => '15s',
        'ignore_protocol_stats' => true,
        'interfaces'            => $_interfaces,
      }],
    ;
    'processes': ;
    'swap': ;
    'system': ;
    'cpu':
      options => [{
        'interval' => '15s',
        'percpu'   => true,
        'totalcpu' => true,
      }],
    ;
    'disk':
      options => [{
        'interval'  => '15s',
        'ignore_fs' => [
          'tmpfs',
          'devtmpfs',
          'devfs',
          'overlay',
          'aufs',
          'squashfs',
          'fd0',
        ],
      }]
    ;
  }

  User <| title == telegraf |> { groups +> 'docker' }
}
