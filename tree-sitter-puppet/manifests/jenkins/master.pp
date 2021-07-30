# Class: profile::jenkins::master
#
# Install a Puppet Labs-approved Jenkins master
#
class profile::jenkins::master (
  Array[String[1]] $doc_urls = ['https://confluence.puppetlabs.com/display/SRE/Jenkins+Instances'],
  Boolean $include_jcasc = false,
  Boolean $install_java_11 = false,
  Boolean $install_jenkins_java = true,
  Boolean $jenkins_use_lts = true,
  Boolean $manage_plugins = false,
  Boolean $manage_ssh = true,
  Boolean $mesos_flag = false,
  Boolean $set_metadata = false,
  Boolean $ssl = false,
  Integer $logrotate_rotate_days = 7,
  Optional[String[1]] $jenkins_logs_to_syslog = undef,
  Optional[String[1]] $metadata_human_name = undef,
  Optional[String[1]] $metadata_owner_uid = undef,
  Optional[String[1]] $metadata_team = undef,
  Optional[String[1]] $site_alias_cname = undef,
  String[1] $jenkins_version = '1.642.2',
  String[1] $site_alias = $facts['networking']['fqdn'],
) {

  include profile::ssl::delivery_wildcard
  include profile::jenkins::params

  if $manage_plugins {
    include profile::jenkins::master::plugins
  }

  if $site_alias {
    meta_motd::keyvalue { "Jenkins site alias: ${site_alias}": }

    telegraf::input { 'prometheus-jenkins-plugin':
      plugin_type => 'prometheus',
      options     => [{
        'urls' => [
          "https://${site_alias}/prometheus/",
        ],
      }],
    }
  }

  class { 'profile::jenkins::master::proxy':
    site_alias       => $site_alias,
    site_alias_cname => $site_alias_cname,
    require_ssl      => $ssl,
  }

  $jenkins_owner          = $profile::jenkins::params::jenkins_owner
  $jenkins_group          = $profile::jenkins::params::jenkins_group
  $master_config_dir      = $profile::jenkins::params::master_config_dir

  # Dependencies:
  #   - pull in apt if we're on Debian
  #   - pull in the 'git' package, used by Jenkins for Git polling
  #   - manage the 'run' directory (fix for busted Jenkins packaging)
  if $facts['os']['family'] == 'Debian' { include apt }

  # configure DNS for referring to mesos URLs without the domain
  if $facts['os']['name'] == 'Centos' {
    $file_content = ['domain delivery.puppetlabs.net',
                    'search delivery.puppetlabs.net',
                    'nameserver	10.240.0.10',
                    'nameserver	10.240.1.10']
    file { '/etc/resolv.conf':
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => join($file_content,"\n"),
    }
  }

  package { 'git':
    ensure => present,
  }

  python::pip { 'psutil':
    ensure => present,
  }

  file { '/var/run/jenkins': ensure => 'directory' }

  # Because our account::user class manages the '${master_config_dir}' directory
  # as the 'jenkins' user's homedir (as it should), we need to manage
  # `${master_config_dir}/plugins` here to prevent the upstream
  # jenkinsci-jenkins module from trying to manage the homedir as the config
  # dir. For more info, see the upstream module's `manifests/plugin.pp`
  # manifest.
  file { "${master_config_dir}/plugins":
    ensure  => directory,
    owner   => $jenkins_owner,
    group   => $jenkins_group,
    mode    => '0755',
    require => [Group[$jenkins_group], User[$jenkins_owner]],
  }

  Account::User <| tag == 'jenkins' |>

  # install java 11 when the variable is set, otherwise
  # when not using the jenkins module's java version, install java8
  if $install_java_11 {
    include profile::jenkins::usage::java11
  } elsif $install_jenkins_java != true {
    include profile::jenkins::usage::java8
  }

  # Manage the heap size on the master, in MB.
  $memory_mb = $facts['memory']['system']['total_bytes']/1024/1024
  if($memory_mb > 8192)
  {
    # anything over 8GB we should keep max 4GB for OS and others
    $heap = sprintf('%.0f', $memory_mb - 4096)
  } else {
    # This is calculated as 50% of the total memory.
    $heap = sprintf('%.0f', $memory_mb * 0.5)
  }

  # manage garbage collection (GC) algorithm
  if $install_jenkins_java {
    #for java7
    $gc_algo = '-XX:+UseConcMarkSweepGC -XX:+CMSClassUnloadingEnabled'
  } else {
    #for java8
    $gc_algo = '-XX:+UseG1GC'
  }

  #manage CI.next mesos cloud queue QENG-4739
  if $mesos_flag {
    $provision_flag = '-Dhudson.slaves.NodeProvisioner.MARGIN=50 -Dhudson.slaves.NodeProvisioner.MARGIN0=0.85 '
  } else {
    $provision_flag = ''
  }

  # the name of the parameter for JAVA flags is different in Debian vs CentOs
  if $facts['os']['family'] == 'RedHat' {
    $java_arg_name = 'JENKINS_JAVA_OPTIONS'
  } else {
    $java_arg_name = 'JAVA_ARGS'
  }

  $main_arguments = {
    $java_arg_name => {
      # pingIntervalSeconds defaults to 300, reducing it to avoid JNLP/agent disconnects
      # enforceNameRestrictions to false because our mesos labels contain a ":" and without this the agent will not be allowed to start
      'value' => "-Xms${heap}m -Xmx${heap}m ${provision_flag}-Dhudson.model.ParametersAction.keepUndefinedParameters=true -Djava.awt.headless=true ${gc_algo} -Dhudson.slaves.ChannelPinger.pingIntervalSeconds=30 -Djenkins.model.Nodes.enforceNameRestrictions=false -Djenkins.security.ApiTokenProperty.adminCanGenerateNewTokens=true",
    },
  }

  # other environment variable to initialize when starting jenkins, used by jenkins as code plugin configurations
  if $include_jcasc {
    $other_arguments = {
      'MYHOSTNAME' => {
        'value' => $site_alias,
      },
    }
    # include files for jcasc, as specified in $jcasc_files
    include profile::jenkins::master::jcasc
  }

  $config_hash = deep_merge($main_arguments, $other_arguments)

  class { 'jenkins':
    cli                => false,
    lts                => $jenkins_use_lts,
    repo               => true,
    version            => $jenkins_version,
    service_enable     => true,
    service_ensure     => running,
    configure_firewall => false,
    install_java       => $install_jenkins_java,
    manage_user        => false,
    manage_group       => false,
    manage_datadirs    => false,
    # Set java params eg heap min and max sizes
    # and other system properties see
    # https://wiki.jenkins-ci.org/display/JENKINS/Features+controlled+by+system+properties
    # https://github.com/jenkinsci/mesos-plugin#over-provisioning-flags
    config_hash        => $config_hash,
  }

  # (QENG-3512) Forward jenkins master logs to syslog
  # When set to facility.level the jenkins_log will use that value instead of a
  # separate log file eg. daemon.info
  if $jenkins_logs_to_syslog {
    $config_hash_to_syslog = {
      'JENKINS_LOG' => {
        'value' => $jenkins_logs_to_syslog,
      },
    }
  } else {
    $config_hash_to_syslog = {}
  }

  create_resources('jenkins::sysconfig', $config_hash_to_syslog)

  # workaround to load the CSP without using the command line -D flag which fails in systemd
  file { "${master_config_dir}/init.groovy.d":
    ensure => directory,
    owner  => $jenkins_owner,
    group  => $jenkins_group,
    mode   => '0774',
  }

  $csp_config = "// groovy file run at startup to set the CSP https://wiki.jenkins.io/display/JENKINS/Configuring+Content+Security+Policy
  System.setProperty(\"hudson.model.DirectoryBrowserSupport.CSP\", \"default-src 'self'; img-src 'self'; style-src 'self';\")
  "

  file { "${master_config_dir}/init.groovy.d/CSP.groovy":
    ensure  => file,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0774',
    content => $csp_config,
  }

  # Deploy SSH keys
  if $manage_ssh {
    file { "${master_config_dir}/.ssh":
      ensure => directory,
      owner  => $jenkins_owner,
      group  => $jenkins_group,
      mode   => '0700',
    }

    file { "${master_config_dir}/.ssh/id_rsa":
      ensure  => file,
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0600',
      content => "${lookup('profile::jenkins::agent::id_rsa_jenkins')}\n",
    }

    file { "${master_config_dir}/.ssh/id_rsa.pub":
      ensure  => file,
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0640',
      content => "${lookup('profile::jenkins::agent::id_rsa_jenkins_pub')}\n",
    }
  }

  # (QENG-1829) Logrotate rules
  # Jenkins' default logrotate config retains too much data: by default, it
  # rotates jenkins.log weekly and retains the last 52 weeks of logs.
  # Considering we almost never look at the logs, let's rotate them daily
  # and discard after 7 days to reduce disk usage.
  logrotate::job { 'jenkins':
    log     => '/var/log/jenkins/jenkins.log',
    options => [
      'daily',
      'copytruncate',
      'missingok',
      "rotate ${logrotate_rotate_days}",
      'compress',
      'delaycompress',
      'notifempty',
    ],
  }

  if $set_metadata {
    profile_metadata::service { $title:
      human_name => $metadata_human_name,
      team       => pick($metadata_team, $profile::monitoring::icinga2::common::owner),
      owner_uid  => $metadata_owner_uid,
      doc_urls   => $doc_urls,
    }
  }
}
