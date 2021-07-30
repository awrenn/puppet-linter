class profile::monitoring::icinga2::ssh {

  include profile::monitoring::icinga2::common
  include profile::monitoring::icinga2::commands
  include profile::server::params

  @@icinga2::object::host { $facts['networking']['fqdn']:
    check_command => 'hostalive',
    display_name  => $trusted['certname'],
    ipv4_address  => $facts['networking']['fqdn'],
    tag           => [$::profile::monitoring::icinga2::common::parent_zone, $facts['classification']['stage']],
  }
  realize Account::User['icingamonitor']

    ssh::allowgroup { 'icingamonitor': }
    package { $::profile::monitoring::icinga2::common::icinga_plugin_packages:
      ensure => 'installed',
      before => File["${::profile::monitoring::icinga2::common::plugin_dir}/artisan"],
    }

    file { "${::profile::monitoring::icinga2::common::plugin_dir}/artisan":
      ensure  => directory,
      source  => 'puppet:///modules/profile/monitoring/icinga2/plugins',
      mode    => '0755',
      recurse => true,
    }
}
