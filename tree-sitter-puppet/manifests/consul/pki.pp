#profile::consul::pki 
#
class profile::consul::pki {
  $_consule_pki_deps = $facts['kernel'] ? {
    'Linux'   => '/etc/consul',
    'windows' => 'C:\\ProgramData\\consul\\config',
  }

  $_consule_pki_dir = $facts['kernel'] ? {
    'Linux'   => '/etc/consul/pki',
    'windows' => 'C:/ProgramData/consul/config/pki',
  }

  $_consule_pki_mode = $facts['kernel'] ? {
    'Linux'   => '0750',
    'windows' => '0770',
  }

  $_consule_pki_owner = $facts['kernel'] ? {
    'Linux'   => 'consul',
    'windows' => 'NT AUTHORITY\\NETWORK SERVICE',
  }

  $_consule_pki_group = $facts['kernel'] ? {
    'Linux'   => 'consul',
    'windows' => 'Administrators',
  }

  file { $_consule_pki_dir:
    ensure  => directory,
    owner   => $_consule_pki_owner,
    group   => $_consule_pki_group,
    mode    => $_consule_pki_mode,
    require => File[$_consule_pki_deps],
  }

  file { 'consul-pki-ca':
    ensure => file,
    path   => "${_consule_pki_dir}/ca.crt",
    source => "${puppet_ssldir}/certs/ca.pem",
    owner  => $_consule_pki_owner,
    group  => $_consule_pki_group,
    mode   => '0640',
  }

  file { 'consul-pki-cert':
    ensure => file,
    path   => "${_consule_pki_dir}/${trusted['certname']}.crt",
    source => "${puppet_ssldir}/certs/${trusted['certname']}.pem",
    owner  => $_consule_pki_owner,
    group  => $_consule_pki_group,
    mode   => '0640',
  }

  file { 'consul-pki-key':
    ensure => file,
    path   => "${_consule_pki_dir}/${trusted['certname']}.pem",
    source => "${puppet_ssldir}/private_keys/${trusted['certname']}.pem",
    owner  => $_consule_pki_owner,
    group  => $_consule_pki_group,
    mode   => '0640',
  }

  case $facts['os']['family'] {
    'Debian': {
      file { '/usr/local/share/ca-certificates/extra':
        ensure => directory,
      }

      file { 'puppetca-os-copy':
        ensure => file,
        path   => '/usr/local/share/ca-certificates/extra/puppetca.crt',
        source => "${puppet_ssldir}/certs/ca.pem",
        owner  => 'root',
        group  => 'root',
        mode   => '0600',
        notify => Exec['/usr/sbin/update-ca-certificates'],
      }

      exec { '/usr/sbin/update-ca-certificates':
        refreshonly => true,
      }
    }
    'Redhat': {
      file { 'puppetca-os-copy':
        ensure => file,
        path   => '/etc/pki/ca-trust/source/anchors/puppetca.pem',
        source => "${puppet_ssldir}/certs/ca.pem",
        owner  => 'root',
        group  => 'root',
        mode   => '0600',
        notify => Exec['/usr/bin/update-ca-trust enable'],
      }

      exec { '/usr/bin/update-ca-trust enable':
        refreshonly => true,
        notify      => Exec['/usr/bin/update-ca-trust extract'],
      }

      exec { '/usr/bin/update-ca-trust extract':
        refreshonly => true,
      }
    }
    'Suse': {
      file { 'puppetca-os-copy':
        ensure => file,
        path   => '/etc/pki/trust/anchors/puppetca.crt',
        source => "${puppet_ssldir}/certs/ca.pem",
        owner  => 'root',
        group  => 'root',
        mode   => '0600',
        notify => Exec['/usr/sbin/update-ca-certificates'],
      }

      exec { '/usr/sbin/update-ca-certificates':
        refreshonly => true,
      }
    }
    'windows': {} # Handled by Class windows_puppet_certificates in profile::os::windows::winrm
    default: { fail("${facts['os']['family']} is not supported") }
  }
}
