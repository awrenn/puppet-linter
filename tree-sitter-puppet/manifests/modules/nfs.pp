# @summary setup NFS exports for modules team CI
#
# This profile sets up NFS exports for modules team to use as part of thier
# CI processes. Vmpooler instances controlled by Jenkins will be the primary
# consumers of any exports defined here so the delivery network should be
# permitted to connect.
#
class profile::modules::nfs {
  include nfs::server

  $export = '/srv/modules_ci'

  file { $export:
    ensure => directory,
    group  => 'modules',
    mode   => '2775',
  }

  $client_perms = '(rw,insecure,async,no_root_squash)'

  $clients = [
    "10.16.112.0/20${client_perms}",
    "10.32.77.0/24${client_perms}",
    "10.32.112.0/20${client_perms}",
  ]

  nfs::server::export { $export:
    ensure  => 'mounted',
    clients => $clients.join(' '),
    require => File[$export],
  }
}

