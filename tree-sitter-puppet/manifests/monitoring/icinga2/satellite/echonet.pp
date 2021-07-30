# Configuration specific to the echonet zone should sit here. For example, checks
# which aren't associated with a host that should run from opdx should be created
# in this class.
class profile::monitoring::icinga2::satellite::echonet inherits ::profile::monitoring::icinga2::satellite {
  Icinga2::Object::Host {
    zone             => $zone,
  }

  #This record needs to exist for echonet satellite nodes because DHCP isn't running.
  @@dns_record { "${facts['networking']['hostname']}.ops.puppetlabs.net":
    ensure  => 'present',
    content => $facts['networking']['ip'],
    type    => 'A',
    ttl     => '4800',
    domain  => 'ops.puppetlabs.net',
  }

  $opdx_ucs_chassis_ids = [ '1', '2', '5', '6', '7', '8' ]
  $pix_ucs_chassis_ids = [ '1', '2' ]

  # Monitoring for UCS which is accessible via echonet
  icinga2::object::host { 'opdx-a1-f1-oob.ops.puppetlabs.net':
    display_name  => 'opdx-a1-f1-oob.ops.puppetlabs.net',
    ipv4_address  => 'opdx-a1-f1-oob.ops.puppetlabs.net',
    check_command => 'hostalive',
  }

  icinga2::object::host { 'pix-600-jj25-f1-oob.ops.puppetlabs.net':
    display_name  => 'pix-600-jj25-f1-oob.ops.puppetlabs.net',
    ipv4_address  => 'pix-600-jj25-f1-oob.ops.puppetlabs.net',
    check_command => 'hostalive',
  }

  $ucs_tests = ['ct', 'ci', 'f', 'po']
  each($opdx_ucs_chassis_ids) |$chassis| {
    each($ucs_tests) |$test| {
      @@icinga2::object::service { "opdx-ucs-chassis-${chassis}-${test}":
        host_name     => 'opdx-a1-f1-oob.ops.puppetlabs.net',
        check_command => 'ucs',
        vars          => {
          'host'             => 'opdx-a1-f1-oob.ops.puppetlabs.net',
          'test'             => $test,
          'object_name'      => "chassis-${chassis}",
          'community_string' => 'plops',
        },
        tag           => ['singleton'],
      }
    }
  }
  each($pix_ucs_chassis_ids) |$chassis| {
    each($ucs_tests) |$test| {
      @@icinga2::object::service { "pix-ucs-chassis-${chassis}-${test}":
        host_name     => 'pix-600-jj25-f1-oob.ops.puppetlabs.net',
        check_command => 'ucs',
        vars          => {
          'host'             => 'pix-600-jj25-f1-oob.ops.puppetlabs.net',
          'test'             => $test,
          'object_name'      => "chassis-${chassis}",
          'community_string' => 'plops',
        },
        tag           => ['singleton'],
      }
    }
  }
}
