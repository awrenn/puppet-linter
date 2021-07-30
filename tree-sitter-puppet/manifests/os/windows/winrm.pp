class profile::os::windows::winrm {
  class { 'windows_puppet_certificates':
    manage_master_cert => true,
    manage_client_cert => true,
  }

  unless $facts['puppet_cert_paths']['ca_path'] {
    fail('The "puppet_cert_paths/ca_path" fact from the "puppetlabs-windows_puppet_certificates" module is missing')
  }

  # winrm quickconfig in PowerShell expects http to be enabled
  winrmssl { $facts['puppet_cert_paths']['ca_path']:
    ensure       => present,
    issuer       => $facts['puppet_cert_paths']['ca_path'],
    disable_http => false,
    require      => Windows_puppet_certificates::Windows_certificate['puppet_master_windows_certificate'],
  }

  # winrm quickconfig in PowerShell expects this registry entry
  registry_value { 'LocalAccountTokenFilterPolicy':
    ensure => present,
    path   => 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\LocalAccountTokenFilterPolicy',
    data   => '1',
    type   => dword,
  }
}
