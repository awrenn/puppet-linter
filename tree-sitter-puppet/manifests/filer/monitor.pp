##
#
class profile::filer::monitor inherits profile::monitoring::icinga2::common {

  include profile::server
  @@icinga2::object::service {
    default:
      check_command      => 'by_ssh',
      template_to_import => 'by_ssh-service',
    ;
    'nfs-insecure':
      vars          => {
        'by_ssh_command' => "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_nfs_insecure.py",
      },
    ;
    'filer-nfs-server-service':
      vars          => {
        'by_ssh_command' => "${::profile::monitoring::icinga2::common::plops_plugin_dir}/check_service_status.py --service network/nfs/server:default",
      },
    ;
  }
}
