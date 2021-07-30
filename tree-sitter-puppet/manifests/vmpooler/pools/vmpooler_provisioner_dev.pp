class profile::vmpooler::pools::vmpooler_provisioner_dev (
  $folder_name = 'vmpooler-provisioner-dev-2',
  $config_file = '/etc/vmpooler/vmpooler-provisioner-dev-2.yaml'
) {

  $base = regsubst($folder_name, '-', '_', 'G')

  profile::vmpooler::pool {
    default:
      datastore   => 'instance3_1',
      size        => 2,
      folder_base => "vmpooler-dev/${folder_name}",
      datacenter  => 'opdx',
      provider    => 'vsphere-ci65',
      config_file => $config_file,
      base        => "${base}_",
      appendage   => '-ci65',
      ;
    "${base}_centos-7-x86_64":
      template => 'templates/centos-7.2-x86_64-0.0.6',
      ;
    "${base}_ubuntu-1804-x86_64":
      template => 'templates/ubuntu-18.04-x86_64-0.0.2',
      ;
    "${base}_redhat-7-x86_64":
      template => 'templates/redhat-7.2-x86_64-0.0.3'
      ;
    "${base}_centos-7-x86_64-pix":
      template     => 'templates/centos-7.2-x86_64-0.0.6',
      datastore    => 'tintri-vmpooler-pix',
      datacenter   => 'pix',
      clone_target => 'acceptance2',
      appendage    => '-pix',
      ;
  }
}
