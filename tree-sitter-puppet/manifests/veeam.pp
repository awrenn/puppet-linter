# Class used to provide the access needed by Veeam Backup and Recovery
# The sudo rights of NOPASSWD:ALL is per the Veeam documentation at
# https://helpcenter.veeam.com/docs/backup/hyperv/credentials_manager_linux_pubkey.html?ver=95
# The '!requiretty' is per support case # 03734746 
class profile::veeam (
  Boolean $package_manage = false,
  Boolean $repo_manage = false,
  Boolean $service_manage = false,
  Hash $config_entries = {},
  Stdlib::IP::Address::V4 $veeam_mount_server_ip = '10.32.22.45',
  ){
  include profile::server

  Account::User <| title == 'veeam' |>
  Group         <| title == 'veeam' |>

  # The associated SSH key is in 1password in the InfraCore vault
  ssh::allowgroup  { 'veeam': }

  sudo::entry { 'profile::veeam':
    entry => @("SUDO"),
      veeam ALL=(ALL) NOPASSWD:ALL
      Defaults:veeam !requiretty
      | SUDO
  }

  if $facts['is_virtual'] == false {
    # this case statement will grow soon to cover more than just the single case
    # covering Debian and RedHat.
    case $facts['os']['family'] {
      'Debian', 'RedHat': {
        if $facts['os']['name'] != 'CumulusLinux' {
          class { 'veeamagent':
            config_entries => $config_entries,
            package_manage => $package_manage,
            repo_manage    => $repo_manage,
            service_manage => $service_manage,
          }
        }
      }
      default: {
        # do nothing
      }
    }
  }

  if $profile::server::fw {
    if $facts['kernel'] != 'SunOS' and $facts['whereami'] !~ /^linode.*/ {
    # https://helpcenter.veeam.com/docs/backup/vsphere/used_ports.html?ver=95#guest
      firewall { '400 Veeam mount server to ports 2500-5000':
        proto  => 'tcp',
        action => 'accept',
        dport  => '2500-5000',
        source => $veeam_mount_server_ip,
      }
    }
  }
}
