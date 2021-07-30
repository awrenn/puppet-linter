# Class: profile::jenkins::agent::linux::jenkins_dir
# Everything related to the jenkins home directory.
#
# @param use_cloud_resources set to false for nodes that do not use cloud resrouces
#
class profile::jenkins::agent::linux::jenkins_dir (
  Boolean $use_cloud_resources = true,
)
{
  $process_cleanup_enabled   = $profile::jenkins::agent::process_cleanup_enabled
  $agent_home                = $profile::jenkins::params::agent_home
  $tmpclean_enabled          = $profile::jenkins::agent::tmpclean_enabled
  $workspace_cleanup_enabled = $profile::jenkins::agent::workspace_cleanup_enabled

  if $use_cloud_resources {
    include profile::jenkins::agent::fog

    $autogenic_aws_key                 = lookup('profile::jenkins::agent::autogenic_aws_key')
    $autogenic_aws_secret_key          = lookup('profile::jenkins::agent::autogenic_aws_secret_key')
    $azure_client_id                   = lookup('profile::jenkins::agent::azure_client_id')
    $azure_client_secret               = lookup('profile::jenkins::agent::azure_client_secret')
    $azure_pem_file                    = lookup('profile::jenkins::agent::azure_pem_file')
    $azure_sub_id                      = lookup('profile::jenkins::agent::azure_sub_id')
    $azure_tenant_id                   = lookup('profile::jenkins::agent::azure_tenant_id')
    $classic_key_id                    = lookup('profile::jenkins::agent::classic_key_id')
    $classic_secret_key                = lookup('profile::jenkins::agent::classic_secret_key')
    $default_ami_key_id                = lookup('profile::jenkins::agent::default_ami_key_id')
    $default_ami_region                = 'us-west-2'
    $default_ami_secret_key            = lookup('profile::jenkins::agent::default_ami_secret_key')
    $docs_key_id                       = lookup('profile::jenkins::agent::docs_key_id')
    $docs_2_key_id                     = lookup('profile::jenkins::agent::docs_2_key_id')
    $docs_secret_key                   = lookup('profile::jenkins::agent::docs_secret_key')
    $docs_2_secret_key                 = lookup('profile::jenkins::agent::docs_2_secret_key')
    $etc_key_id                        = lookup('profile::jenkins::agent::etc_key_id')
    $etc_secret_key                    = lookup('profile::jenkins::agent::etc_secret_key')
    $gserviceaccount_id                = lookup('profile::jenkins::agent::gserviceaccount_id')
    $gserviceaccount_key               = lookup('profile::jenkins::agent::gserviceaccount_key')
    $platform9_jenkins_user_password   = lookup('profile::jenkins::agent::platform9_jenkins_user_password')
    $puppet_discovery_google_auth      = lookup('profile::jenkins::agent::puppet_discovery_google_auth')
    $puppet_discovery_provider_secrets = lookup('profile::jenkins::agent::puppet_discovery_provider_secrets')
    $sauce_labs_access_key             = lookup('profile::jenkins::agent::sauce_labs_access_key')
    $vpc_key_id                        = lookup('profile::jenkins::agent::vpc_key_id')
    $vpc_secret_key                    = lookup('profile::jenkins::agent::vpc_secret_key')
    $easy_dita_creds                   = lookup('profile::jenkins::agent::easy_dita_creds')
  }

  # Temporary fix for QENG-3577 until fix for Jenkins Core (JENKINS-27329) is implemented
  cron { 'save_matrix_workspace':
    ensure  => present,
    user    => 'root',
    command => "find ${agent_home}/workspace -maxdepth 1 -print | xargs touch",
    hour    => '*',
    minute  => 0,
  }

  # QENG-1035 - maintain '/home/jenkins'
  # Some job configs have '/home/jenkins' hard-coded instead of using ${HOME}.
  file { '/home/jenkins':
    ensure  => link,
    target  => $agent_home,
    require => Account::User[$profile::jenkins::params::jenkins_owner],
  }

  file {
    default:
      ensure  => file,
      mode    => '0640',
      owner   => $profile::jenkins::params::jenkins_owner,
      group   => $profile::jenkins::params::jenkins_group,
      require => Account::User[$profile::jenkins::params::jenkins_owner],
    ;
    "${agent_home}/.bashrc":
      mode   => '0755',
    ;
    "${agent_home}/.creds": # a directory to store all credentials
      ensure => directory,
    ;
    "${agent_home}/.gitconfig":
    source  => 'puppet:///modules/profile/jenkins/agent/gitconfig',
    ;
    "${agent_home}/.puppetlabs":
      ensure => directory,
    ;
    "${agent_home}/.puppetlabs/etc":
      ensure => directory,
    ;
    "${agent_home}/.puppetlabs/etc/puppet":
      ensure => directory,
    ;
    "${agent_home}/.ssh":
      ensure => directory,
      mode   => '0700',
    ;
    "${agent_home}/.ssh/config":
      source  => 'puppet:///modules/profile/jenkins/agent/ssh_config',
    ;
    "${agent_home}/.ssh/id_rsa": # Jenkins SSH keys
      mode    => '0600',
      content => "${lookup('profile::jenkins::agent::id_rsa_jenkins')}\n",
    ;
    "${agent_home}/.ssh/id_rsa.pub":
      content => "${lookup('profile::jenkins::agent::id_rsa_jenkins_pub')}\n",
    ;
    "${agent_home}/.ssh/id_rsa-acceptance": # insecure vmpooler SSH keys
      mode    => '0600',
      content => "${lookup('profile::jenkins::agent::id_rsa_acceptance')}\n",
    ;
    "${agent_home}/.ssh/id_rsa-acceptance.pub": # insecure vmpooler SSH keys
      content => "${lookup('profile::jenkins::agent::id_rsa_acceptance_pub')}\n",

    ;
    "${agent_home}/.vanagon-token": # vanagon vmpooler token file
      content => "${lookup('profile::jenkins::agent::vanagon_token')}\n",
    ;
  }

  python::pip { 'psutil':
    ensure => present,
  }

  # If agents don't use cloud resources then they don't need, or may not even
  # have, secrets related to things like AWS, Azure, and Google. All the
  # resources in this block fit into that bucket.
  if $use_cloud_resources {
    file {
      default:
        ensure  => file,
        mode    => '0640',
        owner   => $profile::jenkins::params::jenkins_owner,
        group   => $profile::jenkins::params::jenkins_group,
        require => Account::User[$profile::jenkins::params::jenkins_owner],
      ;
      "${agent_home}/.aws":
        ensure  => directory,
      ;
      "${agent_home}/.aws/config":
        content => template('profile/jenkins/agent/aws_config.erb'),
      ;
      "${agent_home}/.aws/credentials":
        content => template('profile/jenkins/agent/aws_credentials.erb'),
      ;
      "${agent_home}/.creds/${azure_sub_id}.pem":
        content => $azure_pem_file
      ;
      "${agent_home}/.creds/gserviceaccount_perfmetrics.json":
        content => template('profile/jenkins/agent/gserviceaccount_perfmetrics.erb'),
      ;
      "${agent_home}/.puppet_discovery_secrets":
        ensure => directory,
      ;
      "${agent_home}/.puppet_discovery_secrets/puppet_discovery_auth.json":
        content => $puppet_discovery_google_auth,
      ;
      "${agent_home}/.puppet_discovery_secrets/puppet_discovery_provider_secrets.json":
        content => $puppet_discovery_provider_secrets,
      ;
      "${agent_home}/.puppetlabs/etc/puppet/azure.conf":
        content => template('profile/jenkins/agent/azure.conf.erb'),
      ;
      "${agent_home}/.sauce_labs_access_key":
        content => $sauce_labs_access_key,
      ;
      "${agent_home}/.creds/.platform9_jenkins_user_password":
        content => $platform9_jenkins_user_password,
      ;
      "${agent_home}/.ssh/abs-aws-ec2.rsa": # key for AWS EC2 instances
        mode    => '0600',
        content => "${lookup('profile::jenkins::agent::abs_aws_ec2_key')}\n",

      ;
      "${agent_home}/.ssh/google_compute": # key for Google Compute instances
        mode    => '0600',
        content => "${lookup('profile::jenkins::agent::google_compute')}\n",
      ;
      "${agent_home}/.creds/easy_dita_creds":
        content => $easy_dita_creds,
      ;
    }
  }

  if $tmpclean_enabled {
    cron { 'tmpclean':
      ensure  => present,
      user    => 'root',
      command => 'find /tmp -maxdepth 1 -mmin +360 -exec rm -rf {} \;',
      hour    => '*',
      minute  => 0,
    }
  }

  if $workspace_cleanup_enabled {
    file { "${agent_home}/jenkins_workspace_cleanup.py":
      ensure => file,
      owner  => $profile::jenkins::params::jenkins_owner,
      group  => $profile::jenkins::params::jenkins_group,
      mode   => '0755',
      source => 'puppet:///modules/profile/jenkins/agent/utils/jenkins_workspace_cleanup.py',
    }

    cron { 'jenkins_workspace_cleanup':
      ensure  => present,
      user    => 'root',
      command => "${agent_home}/jenkins_workspace_cleanup.py ${agent_home}/workspace",
      hour    => 4,
      minute  => 0,
      require => File["${agent_home}/jenkins_workspace_cleanup.py"],
    }
  } else {
    file { "${agent_home}/jenkins_workspace_cleanup.py":
      ensure => absent,
    }

    cron { 'jenkins_workspace_cleanup':
      ensure => absent,
      user   => 'root',
    }
  }

  if $process_cleanup_enabled {
    file { "${agent_home}/jenkins_process_cleanup.py":
      ensure => file,
      owner  => $profile::jenkins::params::jenkins_owner,
      group  => $profile::jenkins::params::jenkins_group,
      mode   => '0755',
      source => 'puppet:///modules/profile/jenkins/agent/utils/jenkins_process_cleanup.py',
    }

    cron { 'jenkins_process_cleanup':
      ensure  => present,
      user    => 'root',
      command => "${agent_home}/jenkins_process_cleanup.py",
      hour    => range('1', '23', '2'),
      minute  => 35,
      require => [
        File["${agent_home}/jenkins_process_cleanup.py"],
        Python::Pip['psutil'],
      ],
    }
  } else {
    file { "${agent_home}/jenkins_process_cleanup.py":
      ensure => absent,
    }

    cron { 'jenkins_process_cleanup':
      ensure => absent,
      user   => 'root',
    }
  }
}
