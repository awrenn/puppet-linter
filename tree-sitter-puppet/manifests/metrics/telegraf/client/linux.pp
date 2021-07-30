# Telegraf configs specific to Linux
class profile::metrics::telegraf::client::linux (
  Optional[Array[String[1]]] $sysstat_tagdrop = undef
){
  # we manage sysstat on Debian in profile::os::linux::debian via dist/sysstat
  unless $facts['os']['family'] == 'Debian' {
    ensure_packages(['sysstat',])
  }

  $sadc_path = $facts['os']['family'] ? {
    'Debian' => '/usr/lib/sysstat/sadc',
    'RedHat' => '/usr/lib64/sa/sadc',
    'Suse'   => '/usr/lib64/sa/sadc',
    default  => undef,
  }

  unless $sadc_path {
    fail('The path to sadc must be specified')
  }

  $default_sysstat_options = {
      'activities' => [ 'DISK' ],
      'sadc_path'  => $sadc_path,
      'options'    => {
        '-C'     => 'cpu',
        '-B'     => 'paging',
        '-b'     => 'io',
        '-n ALL' => 'network',
        '-P ALL' => 'per_cpu',
        '-q'     => 'queue',
        '-r'     => 'mem_util',
        '-S'     => 'swap_util',
        '-u'     => 'cpu_util',
        '-v'     => 'inode',
        '-W'     => 'swap',
        '-w'     => 'task',
      },
  }

  if $sysstat_tagdrop {
    $_options = $default_sysstat_options + { 'tagdrop' => { 'device' => $sysstat_tagdrop } }
  } else {
    $_options = $default_sysstat_options
  }

  telegraf::input{ 'sysstat':
    options => [$_options],
    require => Package['sysstat'],
  }
}
