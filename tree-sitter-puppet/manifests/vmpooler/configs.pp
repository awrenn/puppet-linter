class profile::vmpooler::configs (
  String $vsphere_password,
  String $config_folder = '/etc/vmpooler'
) {
  case $facts['classification']['stage'] {
    'prod': {
      class { [
        'profile::vmpooler::instance::cinext',
        'profile::vmpooler::instance::provisioner_dev',
        'profile::vmpooler::instance::dev',
      ]:
        vsphere_password => $vsphere_password,
        config_folder    => $config_folder,
      }
    }
    default: {}
  }
}
