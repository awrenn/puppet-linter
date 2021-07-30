class profile::elasticsearch::common {
  # Sets up the package and cluster business
  include profile::elasticsearch::plugins
  include profile::server::params
  include profile::nfs::purge_mounts
  $es_node_ips = sort(puppetdb_query("inventory {
    facts.classification.stage = '${facts['classification']['stage']}' and
    resources {
      type = 'Class' and
      title = 'Profile::Elasticsearch::Common'
    }
  }").map |$value| { $value['facts']['networking']['ip'] })
  $es_hosts = hiera('profile::elasticsearch::cluster_hosts', $es_node_ips)
  $es_home  = hiera('profile::elasticsearch::home', '/usr/share/elasticsearch')
  $data_dir = hiera('profile::elasticsearch::data_dir', '/var/lib/elasticsearch')
  $es_version = hiera('profile::elasticsearch::version', '1.5.0')
  $es_repo_version = hiera('profile::elasticsearch::repo_version', '1.5')
  $es_java_install = hiera('profile::elasticsearch::java_install', true)
  $es_cluster = hiera('elasticsearch::cluster')
  $default_jvm_opts = '"-XX:+UseParNewGC -XX:+UseConcMarkSweepGC"'
  $min_master_nodes = hiera('profile::elasticsearch::min_master_nodes', 3)
  $s3_key_id = hiera('profile::elasticsearch::s3_key_id')
  $s3_secret_key = hiera('profile::elasticsearch::s3_secret_key')
  $init_default_settings = {
    'ES_USER'        => hiera('profile::elasticsearch::user', 'elasticsearch'),
    'ES_GROUP'       => hiera('profile::elasticsearch::group', 'elasticsearch'),
    'ES_HEAP_SIZE'   => hiera('profile::elasticsearch::heap_size', '2g'),
    'ES_JAVA_OPTS'   => hiera('profile::elasticsearch::java_opts', $default_jvm_opts),
    'MAX_OPEN_FILES' => hiera('profile::elasticsearch::open_files', '65535'),
    'DATA_DIR'       => $data_dir,
  }

  if ($::profile::server::params::metrics == true) {
    realize Diamond::Collector['ElasticSearchCollector']
  }

  #    file { "${es_home}/bin/elasticsearch.in.sh":
  #    ensure  => present,
  #      content => template('profile/elasticsearch/elasticsearch.in.sh.erb'),
  #  }

    realize Account::User['elasticsearch']
    realize Group['elasticsearch']

    $es_config = {
      'discovery'   => {
        'zen.ping.multicast.enabled'    => 'false',
        'zen.ping.unicast.hosts'        => $es_hosts,
        'zen.ping.timeout'              => '5s',
        'zen.minimum_master_nodes'      => $min_master_nodes,
      },
      'cluster'                                         => {
        'name'                                          => $es_cluster,
        'routing.allocation.node_concurrent_recoveries' =>  '32',
        'routing.allocation.disk.watermark.low'        => '90%',
      },
      'cloud'    => {
        'aws.access_key' => $s3_key_id,
        'aws.secret_key' => $s3_secret_key,
      },
      'node'   => {
        'name' => $facts['networking']['hostname'],
        'data' => 'true',
        'http' => 'true',
      },
      'settings' => {
        'number_of_shards' => 2,
        'number_of_replicas' => 1,
        'index' => {
          'query' => {
            'default_field' => '"message"',
          },
          'store' => {
            'compress' => {
              'stored' => 'true',
              'tv'    => 'true',
            },
          },
        },
      },
      'bootstrap'  => {
        'mlockall' => 'true',
      },
      'indicies'                      => {
        'memory.index_buffer_size'    => '50%',
        'fielddata.cache.size'        => '30%',
      },
      'index'                                       => {
        'search.slowlog.threshold.query.warn'       => '10s',
        'search.slowlog.threshold.query.info'       => '5s',
        'search.slowlog.threshold.query.debug'      => '2s',
        'search.slowlog.threshold.fetch.warn'       => '1s',
        'search.slowlog.threshold.fetch.info'       => '800ms',
        'search.slowlog.threshold.fetch.debug'      => '500ms',
        'indexing.slowlog.threshold.fetch.warn'     => '10s',
        'indexing.slowlog.threshold.fetch.info'     => '5s',
        'indexing.slowlog.threshold.fetch.trace'    => '2s',
      },
    }
}
