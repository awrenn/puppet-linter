# Provide checks for the always-be-scheduling service
# QENG-4707
class profile::abs::monitor {

  # QENG-4707
  @@icinga2::object::service {
    'check_abs_frontend_k8s-abs-prod':
      check_command  => 'abs_frontend',
      check_interval => '5m',
      action_url     => 'https://confluence.puppetlabs.com/display/SRE/Icinga2+checks+that+may+escalate#Icinga2checksthatmayescalate-Checkabsfrontend',
      vars           => {
        'abs_host' => 'abs-prod.k8s.infracore.puppet.net',
        'timeout'  => 5,
        'owner'    => 'dio',
        'escalate' => true,
      },
      tag            => ['singleton'],
      ;
    'check_abs_frontend_k8s-abs-test':
      check_command  => 'abs_frontend',
      check_interval => '5m',
      action_url     => 'https://confluence.puppetlabs.com/display/SRE/Icinga2+checks+that+may+escalate#Icinga2checksthatmayescalate-Checkabsfrontend',
      vars           => {
        'abs_host' => 'abs-test.k8s.infracore.puppet.net',
        'timeout'  => 5,
        'owner'    => 'dio',
      },
      tag            => ['singleton'],
      ;
    'check_abs_frontend_k8s-abs-stage':
      check_command  => 'abs_frontend',
      check_interval => '5m',
      action_url     => 'https://confluence.puppetlabs.com/display/SRE/Icinga2+checks+that+may+escalate#Icinga2checksthatmayescalate-Checkabsfrontend',
      vars           => {
        'abs_host' => 'abs-stage.k8s.infracore.puppet.net',
        'timeout'  => 5,
        'owner'    => 'dio',
      },
      tag            => ['singleton'],
      ;
  }
}
