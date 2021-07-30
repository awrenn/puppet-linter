# Class: profile::veeam::standin
# This will setup a host to act as a standin for hosts that cannot be backed up
# directly by Veeam. This includes things like UCS chassis. It also acts as a
# place for applications to place backups they generate so that these backups
# can be utilized via Veeam.
#
class profile::veeam::standin (
  Sensitive[Array[Hash]] $sensitive_vcenters,
  Sensitive[String] $sensitive_grafana_api_token,
  Sensitive[String] $sensitive_vault_backup_sa_keyfile,
){
  include profile::veeam::standin::webdav
  include jq

  unless $facts['os']['name'] == 'CentOS' {
    fail('profile::veeam::standin only supports CentOS')
  }

  unwrap($sensitive_vcenters).each |Hash $vc| {
    $args = [
      '--quiet',
      "--server ${vc['fqdn']}",
      "--datacenter ${vc['datacenter']}",
      "--user ${vc['user']}",
    ]

    if $vc['exclude-dirs'] {
      $exclude_dirs = $vc['exclude-dirs'].map |String $exclude| {
        "--exclude-dir '${exclude}'"
      }
      $exclude_dir_string = join($exclude_dirs, ' ')
    } else {
      $exclude_dir_string = ''
    }

    $script = '/backup-tools/dump-vcenter-folders.sh'
    $arg_string = join($args + $exclude_dir_string, ' ')
    $output = "/backup-data/${vc['fqdn']}_${vc['datacenter']}_folders.json"

    cron { "backup_${vc['fqdn']}_${vc['datacenter']}_folders":
      hour        => 11,
      minute      => 0,
      environment => Sensitive("VCENTER_PASSWORD='${vc['password']}'"),
      command     => "${script} ${arg_string} > ${output}",
    }
  }

  cron { 'backup_grafana_dashboards':
    hour    => 9,
    minute  => 0,
    command => '/backup-tools/fetch-grafana-dashboards.sh 2>&1 | /usr/bin/logger -t fetch-grafana-dashboards',
    require => File['/backup-tools/fetch-grafana-dashboards.sh'],
  }

  cron { 'backup_grafana_old_onprem_dashboards':
    hour    => 9,
    minute  => 0,
    command => '/backup-tools/fetch-grafana-old-onprem-dashboards.sh 2>&1 | /usr/bin/logger -t fetch-grafana-old-onprem-dashboards',
    require => File['/backup-tools/fetch-grafana-old-onprem-dashboards.sh'],
  }

  cron { 'backup_vault_dev':
    hour    => 2,
    minute  => 0,
    command => '/backup-tools/vault-backup.sh infracore gs://pl-vault-be1-dev /backup-data/vault-backups/ /backup-data/vault-backups /backup-data/vault-backups/vault-backup-user.json',
    require => File['/backup-tools/vault-backup.sh'],
  }

  cron { 'backup_vault_prod':
    hour    => 2,
    minute  => 15,
    command => '/backup-tools/vault-backup.sh infracore gs://pl-vault-be1-prod /backup-data/vault-backups/ /backup-data/vault-backups /backup-data/vault-backups/vault-backup-user.json',
    require => File['/backup-tools/vault-backup.sh'],
  }

  file {
    default:
      ensure => file,
      group  => 'root',
      owner  => 'root',
      mode   => '0755',
    ;
    '/backup-data':
      ensure => directory,
      mode   => '0711',
    ;
    '/backup-data/grafana-cloud':
      ensure => directory,
      mode   => '0711',
    ;
    '/backup-data/grafana-old-onprem-cloud':
      ensure => directory,
      mode   => '0711',
    ;
    '/backup-data/vault-backups':
      ensure => directory,
      mode   => '0711',
    ;
    '/backup-data/vault-backups/vault-backup-user.json':
      content => unwrap($sensitive_vault_backup_sa_keyfile),
      mode    => '0700',
    ;
    '/backup-tools':
      ensure => directory,
    ;
    '/backup-tools/dump-vcenter-folders.sh':
      content => @(SCRIPT),
        #!/bin/bash
        source /opt/rh/rh-ruby25/enable
        /backup-tools/vsphere-folder-copy/dump-vcenter-folders.rb "$@"
        |SCRIPT
    ;
    '/backup-tools/fetch-grafana-dashboards.sh':
      content => epp('profile/veeam/fetch-grafana-dashboards.epp', {
        'sensitive_grafana_api_token' => $sensitive_grafana_api_token,
        'output_dir'                  => '/backup-data/grafana-cloud',
      }),
      require => Package['jq'],
    ;
    '/backup-tools/fetch-grafana-old-onprem-dashboards.sh':
      content => epp('profile/veeam/fetch-grafana-old-onprem-dashboards.epp', {
        'output_dir' => '/backup-data/grafana-old-onprem-cloud',
      }),
      require => Package['jq'],
    ;
    '/backup-tools/vault-backup.sh':
      source => 'puppet:///modules/profile/veeam/standin/vault-backup.sh'
    ;
    '/usr/local/bin/git':
      content => @(SCRIPT),
        #!/bin/bash
        source /opt/rh/rh-git29/enable
        git "$@"
        |SCRIPT
      require => Package['rh-git29'],
    ;
  }

  profile::veeam::standin::user {
    'vcenterbackup':
      data_dir => 'vcenter_backups',
    ;
    'ucsbackup':
      data_dir => 'ucs_backups',
    ;
  }

  File['/backup-tools'] -> Vcsrepo <| |>
  File['/usr/local/bin/git'] -> Vcsrepo <| |>

  vcsrepo {
    default:
      ensure   => latest,
      provider => git,
    ;
    '/backup-tools/vsphere-folder-copy':
      source => 'https://github.com/Sharpie/vsphere-folder-copy.git',
    ;
  }

  package {
    default:
      ensure => present,
    ;
    'centos-release-scl-rh':
    ;
    'rh-git29':
      require => Package['centos-release-scl-rh'],
    ;
    ['rh-ruby25', 'rh-ruby25-ruby-devel',]:
      require => Package['centos-release-scl-rh'],
    ;
  }

  profile::scl_gem { 'rh-ruby25_rbvmomi':
    ensure =>  latest,
  }

  $files_to_rotate = [
    '/backup-data/ucs_backups/opdx-a1-f1-all*',
    '/backup-data/ucs_backups/opdx-a1-f1-full*',
    '/backup-data/ucs_backups/pix-600-jj25-f1-all*',
    '/backup-data/ucs_backups/pix-600-jj25-f1-full*',
  ]

  $files_to_rotate.each |$path| {
    profile::rotate_files { $path:
      keep => 1,
      user => 'ucsbackup',
    }
  }

  tidy {'grafana backup dashboards':
    path    => '/backup-data/grafana-cloud',
    recurse => 1,
    age     => '1w',
  }

  tidy {'grafana old on prem backup dashboards':
    path    => '/backup-data/grafana-old-onprem-cloud',
    recurse => 1,
    age     => '1w',
  }
}
