class profile::graphite::common (
  $cache_instances      = {
      'cache:b' =>  {
        'LINE_RECEIVER_PORT'    => 2113,
        'PICKLE_RECEIVER_PORT'  => 2114,
        'CACHE_QUERY_PORT'      => 7102,
      },
      'cache:c' =>  {
        'LINE_RECEIVER_PORT'    => 2213,
        'PICKLE_RECEIVER_PORT'  => 2214,
        'CACHE_QUERY_PORT'      => 7202,
      },
      'cache:d' =>  {
        'LINE_RECEIVER_PORT'    => 2313,
        'PICKLE_RECEIVER_PORT'  => 2314,
        'CACHE_QUERY_PORT'      => 7302,
      },
    }
) {

  # Enable sloppy backports if wheezy
  if $facts['os']['distro']['codename'] == 'wheezy' {
    apt::source { 'debian_wheezy_sloppy_backports':
      location => hiera('profile::os::linux::debian::vanilla::main_apturl'),
      release  => 'wheezy-backports-sloppy',
    }
  }

  # Put symlink so logs show up in an expected location
  file { '/var/log/graphite':
    ensure => link,
    target => '/opt/graphite/storage/log/',
  }

  $cluster_servers = hiera('profile::graphite::cluster_servers', ['127.0.0.1'])
  # Append correct ports to each $cluster_server
  $cluster_servers_web = $cluster_servers.map |$hosts| { join([$hosts, ':80']) }
  $cluster_servers_2003 = $cluster_servers.map |$hosts| { join([$hosts, ':2003']) }
  $cluster_servers_2004 = $cluster_servers.map |$hosts| { join([$hosts, ':2004']) }

  $schema = [
    {
      name       => 'atlassian test db',
      pattern    => 'stats.net.puppetlabs.ops.atlassian-db\d*-test.postgres.*',
      retentions => '5m:1d,1h:2w'
    },
    {
      name       => 'carbon',
      pattern    => '^carbon\.',
      retentions => '60:90d'
    },
    {
      name       => 'cloudwatch',
      pattern    => '^cloudwatch\.',
      retentions => '5m:31d,1h:93d'
    },
    {
      name       => 'statsd vulcan',
      pattern    => '^stats\.vulcan.*',
      retentions => '5s:36h,1m:9d,5m:180d'
    },
    {
      name       => 'statsd forge',
      pattern    => '^stats.*\.forge\.*',
      retentions => '5s:36h,1m:9d,5m:180d'
    },
    {
      name       => 'graphite indices',
      pattern    => '^stats.*.elasticsearch.indices.*',
      retentions => '60s:1d,5m:7d'
    },
    {
      name       => 'diamond',
      pattern    => '^stats.(com|net).*',
      retentions => '60s:1d,5m:7d,1h:365d'
    },
    {
      name       => 'statsd',
      pattern    => '^stats.*',
      retentions => '10s:6h,1min:6d,10min:1800d'
    },
    {
      name       => 'pdu information',
      pattern    => 'switches.o?pdx-\w+-pdu-*',
      retentions => '60s:1d,5m:7d,1h:365d'
    },
    {
      name       => 'stor-backup kstats',
      pattern    => 'stats.net.puppetlabs.ops.stor-backup*.kstats.*',
      retentions => '1h:90d,6h:180d,1d:730d'
    },
    {
      name       => 'switch traffic',
      pattern    => 'switches.*',
      retentions => '1m:4w,10m:3y'
    },
    {
      name       => 'vmware datatstore stats',
      pattern    => 'vmware.datastore.*',
      retentions => '5m:7d,1h:365d'
    },
    {
      name       => 'vmware cluster stats',
      pattern    => 'vmware.cluster.*',
      retentions => '15m:7d,1h:365d'
    },
    {
      name       => 'default',
      pattern    => '.*',
      retentions => '60s:1d,5m:7d,1h:365d'
    },
  ]
}
