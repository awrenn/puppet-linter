# Class: profile::mesos::slave::job::qe
#
class profile::mesos::slave::job::qe {

  Class['profile::mesos::slave'] -> Class['profile::mesos::slave::job::qe']

  $basedir    = "${::profile::mesos::slave::staging_dir}/qe"
  $deploy_key = "${basedir}/deploy-keys/qe-chronos-jobs.key"

  include profile::repo::params

  file { [$basedir, "${basedir}/deploy-keys"]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { $deploy_key:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => "${lookup('profile::jenkins::agent::mesos_deploy_keys::qe_chronos_jobs')}\n",
  }

  vcsrepo { "${basedir}/qe-chronos-jobs":
    ensure   => present,
    provider => git,
    source   => 'git@github.com:puppetlabs/qe-chronos-jobs',
    revision => 'master',
    identity => $deploy_key,
    require  => File[$deploy_key],
  }

  # Manage the parent directory of the virtualenv
  file { ["${basedir}/virtualenvs", "${basedir}/virtualenvs/qe-chronos-jobs"]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0775',
  }

  python::virtualenv { "${basedir}/virtualenvs/qe-chronos-jobs/vmpooler_status":
    ensure       => present,
    version      => 'system',
    requirements => "${basedir}/qe-chronos-jobs/vmpooler_status/requirements.txt",
    proxy        => $::profile::repo::params::proxy_url,
  }
}
