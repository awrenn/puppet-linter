# Set up the Windows firewall
class profile::fw::windows {
  include profile::os::windows
  include windows_firewall

  windows_firewall::exception {
    default:
      ensure      => present,
      enabled     => true,
      direction   => 'in',
      action      => 'allow',
      protocol    => 'TCP',
      remote_port => 'any',
    ;
    'RDP':
      ensure       => profile::bool2ensure($profile::os::windows::rdp),
      local_port   => 3389,
      display_name => 'Windows Remote Desktop',
      description  => 'Inbound rule for RDP connections. [TCP 3389]',
    ;
    'SSH':
      local_port   => 22,
      display_name => 'OpenSSH',
      description  => 'Inbound rule for SSH connections. [TCP 22]',
    ;
    'WINRM':
      local_port   => 5985,
      display_name => 'Windows Remote Management HTTP-In',
      description  => 'Inbound rule for Windows Remote Management via WS-Management. [TCP 5985]',
    ;
    'WINRM_HTTPS':
      local_port   => 5986,
      display_name => 'Windows Remote Management HTTPS-In',
      description  => 'Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]',
    ;
  }
}
