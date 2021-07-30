##
#
class profile::monitoring::icinga2::common(
  String[1]                      $owner,
  String[1]                      $agent_provider           = 'icinga2-client',
  String[1]                      $application              = 'icinga2',
  String[1]                      $db_user                  = 'icinga2',
  Optional[String[1]]            $db_pass                  = undef,
  Pattern[/\A\d{1,5}\Z/]         $db_port                  = '5432',
  String[1]                      $conf_dir                 = '/etc/icinga2',
  Boolean                        $escalate_host_alerts     = true,
  Boolean                        $ticket_host_alerts       = false,
  Array[String[1]]               $features_enabled         = ['checker', 'notification', 'command'],
  String[1]                      $icinga2_environment      = $facts['classification']['stage'],
  Optional[Hash[String, String]] $notification_credentials = undef,
  String[1]                      $notification_period      = '24x7',
  Boolean                        $notify_chat              = true,
  Optional[String[1]]            $parent_zone              = undef,
  String[1]                      $zone                     = $trusted['certname'],
  String[1]                      $package_ensure           = latest,
){

  # This logic exists in the Icinga2 module, but if the client isn't used the module is never included so this is mostly useful to make the profile stand-alone.
  case $facts['os']['family'] {
    'Debian': {
      $icinga_plugin_packages = [ 'nagios-plugins-standard', 'nagios-plugins-basic', 'nagios-plugins', 'nagios-nrpe-plugin' ]
      $plugin_dir = '/usr/lib/nagios/plugins'
      $icinga2_user = 'nagios'
      $plops_plugin_dir = '/etc/icinga2/scripts/plugins'

      if ! ($package_ensure in ['present', 'latest']) {
        # Exec because puppet can't handle metapackages well that have multiple dependencies
        # If we simply try to manage the icinga2 package at a version, it will try to install
        # the dependencies to the latest version instead of the same version
        # If we try to install the dependencies first, it breaks because icinga2-common tries
        # to start icinga2 after being installed, which fails since the other packages aren't there
        # or managed yet by puppet, which causes more failures.
        exec { 'Install icinga2':
          command => "apt-get update; apt-get install -y icinga2=${package_ensure} icinga2-common=${package_ensure} icinga2-bin=${package_ensure}",
          unless  => "dpkg -s icinga2 | grep -q --fixed-strings --line-regexp 'Version: ${package_ensure}'",
          require => Apt::Source['ops-apt.puppet.com'],
        } -> Package['icinga2']
      }
    }
    'FreeBSD': {
      $icinga_plugin_packages = 'net-mgmt/nagios-plugins'
      $plops_plugin_dir = '/etc/icinga2/scripts/plugins'
          }
    'Solaris': {
      $icinga_plugin_packages = 'system/monitoring/nagios-plugins'
      $plugin_dir    = '/usr/local/libexec'
      $icinga2_user = 'icingamonitor'
      $plops_plugin_dir = "${plugin_dir}/artisan"
    }
    'RedHat': {
      $icinga_plugin_packages = [ 'nagios-plugins-nrpe', 'nagios-plugins', 'nagios-plugins-all' ]
      $icinga2_user = 'icinga'
      $plops_plugin_dir = '/etc/icinga2/scripts/plugins'
      case $facts['os']['architecture'] {
        'x86_64': {
          $plugin_dir = '/usr/lib64/nagios/plugins'
        }
        'i386': {
          $plugin_dir = '/usr/lib/nagios/plugins'
        }
        default: { fail( "${facts['os']['architecture']} unsupported by Class[Monitoring::Icinga2::Common]") }
      }

      if $facts['os']['release']['major'] == '7' {
        # OPS-14260: A CentOS 7 kernel upgrade broke Icinga. Work around:
        file { '/usr/sbin/icinga2':
          ensure    => file,
          owner     => 'root',
          group     => 'root',
          mode      => '0755',
          source    => 'puppet:///modules/profile/monitoring/icinga2/centos_fix_sbin.sh',
          subscribe => Package['icinga2'],
          notify    => Service['icinga2'],
        }
      }
    }
    default: {
      fail("Profile::Monitoring::Icinga2::Common does not support osfamily ${facts['os']['family']}")
    }
  }

  $db_instances = query_resources("stage = ${icinga2_environment}", 'Class[Profile::Monitoring::Icinga2::Db]')
  if is_hash($db_instances) {
    $db_nodes = keys($db_instances)
  } else {
    $db_nodes = $db_instances.map |$x| { $x['certname'] }
  }

  $db_host = hiera('profile::monitoring::icinga2::common::db_host', $db_nodes[0])

  $web_instances = query_resources("stage = ${icinga2_environment}", 'Class[Profile::Monitoring::Icinga2::Web]')
  if is_hash($web_instances) {
    $web_nodes = keys($web_instances)
  } else {
    $web_nodes = $web_instances.map |$x| { $x['certname'] }
  }


  if $parent_zone != undef {
    #TODO: This currently returns facts for the parent nodes. It should be changed to return a resource hash for the parameters of the Icinga2 common class.
    $parent_nodes = query_facts("Class[Profile::Monitoring::Icinga2::Common]{zone='${parent_zone}' and icinga2_environment='${icinga2_environment}'}", ['fqdn', 'ipaddress'])
    $master_zone_query = query_resources('Class[Profile::Monitoring::Icinga2::Master]', "Class[Profile::Monitoring::Icinga2::Common]{icinga2_environment='${icinga2_environment}'}")
    # If more than one Class is returned then we pick one because the value of the zone parameter should be the same because this indicates that there are multiple masters in the same zone.
    $master_zones = $master_zone_query.map |$x| { $x['parameters']['zone'] }
    $master_zone = $master_zones[0]
  }
  $child_nodes = query_resources(false, "Class[Profile::Monitoring::Icinga2::Common]{parent_zone='${zone}' and icinga2_environment='${icinga2_environment}'}")
  $zone_instances = query_resources(false, "Class[Profile::Monitoring::Icinga2::Common]{zone='${zone}' and icinga2_environment='${icinga2_environment}'}")
  if is_hash($zone_instances) {
    $zone_nodes = delete(keys($zone_instances), $trusted['certname'])
  } else {
    $zone_nodes = delete($zone_instances.map |$x| { $x['certname'] }, $trusted['certname'])
  }

  # Sort through all zone_instances (masters or satellites in the same zone)
  # and grab the first one in a sorted list.  Used it for singleton host/service declarations in the
  # satellite files
  if $::profile::monitoring::icinga2::common::zone_instances != [] {
    $master_host = sort($::profile::monitoring::icinga2::common::zone_instances.map |$x| { $x['certname']})[0]
  }
  else {
    $master_host = $trusted['certname']
  }

  Icinga2::Object::Service {
    host_name  => $trusted['certname'],
    zone       => $zone,
  }

  python::pip { ['pynagios', 'nagioscheck', 'py-dateutil']:
    ensure => latest,
  }

  include profile::python::requests
}
