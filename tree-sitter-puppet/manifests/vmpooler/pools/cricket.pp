class profile::vmpooler::pools::cricket (
  $folder_name = 'vmpooler-dev',
  $config_file = '/etc/vmpooler/vmpooler-dev.yaml'
) {

  $base = regsubst($folder_name, '-', '_', 'G')

  ::profile::vmpooler::pool {
    default:
      datastore    => 'vmpooler_acceptance2',
      size         => 1,
      pool_alias   => 'none',
      folder_base  => $folder_name,
      datacenter   => 'pix',
      clone_target => 'acceptance2',
      provider     => 'vsphere-ci65',
      config_file  => $config_file,
      base         => "${base}_",
      ;
    "${base}_dev-pool":
      template => 'templates/redhat-7.2-x86_64-0.0.3',
      ;
    "${base}_dev-pool-A-2":
      template => 'templates/redhat-7.2-x86_64-0.0.3',
      size     =>  2,
      ;
    "${base}_dev-pool-B-2":
      template => 'templates/redhat-7.2-x86_64-0.0.3',
      size     =>  2,
      ;
    "${base}_dev-pool-C-3":
      template => 'templates/redhat-7.2-x86_64-0.0.3',
      size     =>  3,
      ;
  }
}
