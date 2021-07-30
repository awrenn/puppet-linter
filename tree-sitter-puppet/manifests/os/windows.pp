# Basic necessities we expect to have on all Windows machines.
#
# NOTE: We set chocolatey to be the default package provider on Windows in site.pp
class profile::os::windows (
  Boolean                            $rdp                   = true,
  Boolean                            $enable_auto_update    = false,
  Hash[String[1], Profile::Ssh::Key] $additional_admin_keys = {},
) {
  include profile::chocolatey
  include profile::os
  include profile::os::windows::winrm
  include profile::security::sophos_endpoint
  include vmtools_win # This won't do anything on non-VMware nodes.

  realize(Account::User['Administrator'])
  realize(Account::User['windowsteam'])
  Account::User <| groups == 'dio' |>
  Account::User <| groups == 'itops' |>

  account::grant::administrators { 'dio': }
  account::grant::administrators { 'itops': }
  account::grant::rdp { 'windowsteam': }
  account::grant::rdp { 'dio': }
  account::grant::rdp { 'itops': }
  ssh::allowgroup { 'dio': }
  ssh::allowgroup { 'itops': }

  $additional_admin_keys.each |$comment, $info| {
    ssh::authorized_key { "Administrator:${comment}":
      ensure  => present,
      user    => 'Administrator',
      type    => $info['type'],
      key     => $info['key'],
      options => $info['options'],
    }
  }

  # By default puppet isn't in %PATH
  windows_env { 'PATH=%ProgramFiles%\Puppet Labs\Puppet\bin':
    type => 'REG_EXPAND_SZ',
  }

  # Ensure certain system services are enabled and running
  service { 'lmhosts':
    ensure => running,
    enable => true,
  }

  # Ensure that the Print Spooler is not running due to CVE-2021-34527
  service { 'Spooler':
    ensure => stopped,
    enable => false,
  }

  # to have a easily understood class param we end up needing to 
  # flip the provided boolean for use by the wsus_client
  $no_auto_update = $enable_auto_update ? {
    true  => false,
    false => true,
  }

  # Enable/disable Windows automatic updates
  class { 'wsus_client':
    no_auto_update => $no_auto_update,
  }

  $auto_login_keys = [
    'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DefaultUserName',
    'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DefaultPassword',
  ]

  # disable automatic login
  registry_key { $auto_login_keys:
    ensure => absent,
  }

  # Always show hidden folders
  $hidden_folders_key = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Folder\Hidden\SHOWALL'

  registry::value {
    'Enable-RDP':
      key  =>'HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\fDenyTSConnections',
      type => 'dword',
      data => Integer(! $rdp),
    ;
    'Hidden-Folders-Checked-Value':
      key   => $hidden_folders_key,
      value => 'CheckedValue',
      type  => 'dword',
      data  => 1,
    ;
    'Hidden-Folders-Type':
      key   => $hidden_folders_key,
      value => 'Type',
      type  => 'string',
      data  => 'radio',
    ;
    'Procexp-As-Task-Manager': # Use Sysinternals' Process Explorer as an alternate to the Task Manager
      key     => 'HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe',
      value   => 'Debugger',
      data    => 'c:/tools/sysinternals/procexp.exe',
      type    => 'string',
      require => Package['sysinternals'],
    ;
  }

  # Common packages for all Windows systems with chocolatey
  $common_win_packages = [
    '7zip.commandline',
    'curl',
    'powershell-core',
    'powershell',
    'sysinternals',
    'vim-tux',
    'Wget',
  ]

  ensure_packages($common_win_packages, { 'ensure'  => 'latest' })

  pspackageprovider {'Nuget':
    ensure   => present,
    provider => 'windowspowershell',
  }
}
