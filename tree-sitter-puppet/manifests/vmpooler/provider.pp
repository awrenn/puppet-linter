define profile::vmpooler::provider (
  String $server,
  String $username,
  String $password,
  String $provider_class = 'vsphere',
  String $config_file = '/var/lib/vmpooler/vmpooler.yaml',
  String $provider_name = $title,
  Optional[String] $datacenter = undef,
  Optional[Boolean] $insecure = undef,
  Optional[Integer] $connection_pool_size = undef,
  Optional[Integer] $connection_pool_timeout = undef,
  Optional[Boolean] $purge_unconfigured_folders = undef,
  Optional[Array[String]] $purge_folder_whitelist = undef,
) {
  concat::fragment { "vmpooler_provider_${title}":
    target  => $config_file,
    content => template('profile/vmpooler/config_provider.yaml.erb'),
    order   => '02',
  }
}
