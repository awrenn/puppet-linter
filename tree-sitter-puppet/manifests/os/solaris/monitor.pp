##
#
class profile::os::solaris::monitor inherits ::profile::monitoring::icinga2::common {

  include ruby

  $plugin_directory = $::profile::monitoring::icinga2::common::plops_plugin_dir

  @@icinga2::object::service { 'zfs':
    template_to_import => 'by_ssh-service',
    check_command      => 'by_ssh',
    vars               => {
      'by_ssh_command' => "${plugin_directory}/check_zfs.rb",
      'escalate'       => true,
    },
  }

  file {
    default:
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0555'
      ;
    '/opt/puppetlabs/facter/facts.d/has_ipmp.py':
      source => 'puppet:///modules/profile/os/solaris/has_ipmp.py'
      ;
    '/opt/puppetlabs/facter/facts.d/zpools.py':
      source => 'puppet:///modules/profile/os/solaris/zpools.py'
      ;
  }

  if $::has_ipmp {
    @@icinga2::object::service { 'check_ipmp':
      template_to_import => 'by_ssh-service',
      check_command      => 'by_ssh',
      vars               => {
        'by_ssh_command' => "${plugin_directory}/check_ipmp.py",
        'escalate'       => true,
      },
    }
  }

  if $::zpools {
    split($zpools, ':').each |$zpool| {
      @@icinga2::object::service { "check_disk_${zpool}":
        template_to_import => 'by_ssh-service',
        check_command      => 'by_ssh',
        vars               => {
          'by_ssh_command' => "${::profile::monitoring::icinga2::common::plugin_dir}/check_disk -w 6% -c 3% -W 6% -K 3% -l /${zpool}",
          'escalate'       => true,
        },
      }
    }
  }
}
