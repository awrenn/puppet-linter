define profile::vmpooler::pool (
  String $datastore,
  String $folder_base,
  Integer $size = 10,
  String $datacenter = 'opdx',
  String $config_file = '/var/lib/vmpooler/vmpooler.yaml',
  Optional[Variant[Array[String], String]] $pool_alias = undef,
  Optional[String] $template = undef,
  Optional[String] $clone_target = undef,
  Optional[Integer] $ready_ttl = undef,
  Optional[Integer] $timeout = undef,
  Optional[String] $provider = undef,
  Optional[String] $appendage = undef,
  Optional[String] $base = undef,
  Optional[Boolean] $create_linked_clone = undef,
  Optional[String] $snapshot_mainmem_ioblockpages = undef,
  Optional[String] $snapshot_mainmem_iowait = undef
) {

  if $base {
    $filtered_title = delete($title, $base)
  } else {
    $filtered_title = $title
  }

  if $appendage {
    $title_stripped = delete($filtered_title, $appendage)
    $pool_alias_inter = $title_stripped
  } else {
    $title_stripped = $filtered_title
    if $pool_alias {
      unless $pool_alias == 'none' {
        $pool_alias_inter = $pool_alias
      }
    } else {
      if $filtered_title =~ /x86_64/ {
        $pool_alias_inter = [
          regsubst($filtered_title, 'x86_64', '64'),
          regsubst($filtered_title, 'x86_64', 'amd64'),
        ]
      } else {
        $pool_alias_inter = regsubst($filtered_title, 'i386', '32')
      }
    }
  }

  if $template {
    $template_final = $template
  } else {
    $template_final = "templates/${title_stripped}"
  }

  $folder = "${folder_base}/${title_stripped}"

  if $pool_alias_inter {
    $pool_alias_format = join(any2array($pool_alias_inter).map |$p| { "'${p}'" }, ', ')
  }

  concat::fragment { "vmpooler_pool_${title}":
    target  => $config_file,
    content => template('profile/vmpooler/config_pool.yaml.erb'),
  }
}
