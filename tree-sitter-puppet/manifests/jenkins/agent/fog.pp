# Class: profile::jenkins::agent::fog
# Install and configure a .fog file for use by a Jenkins agent
#
class profile::jenkins::agent::fog (
  Sensitive[String[1]] $sensitive_default_aws_access_key_id,
  Sensitive[String[1]] $sensitive_default_aws_dev_access_key_id,
  Sensitive[String[1]] $sensitive_default_aws_dev_secret_access_key,
  Sensitive[String[1]] $sensitive_default_aws_secret_access_key,
  Sensitive[String[1]] $sensitive_default_static_vcenter_password,
  Sensitive[String[1]] $sensitive_default_vmpooler_token,
  Sensitive[String[1]] $sensitive_default_vsphere_password,
  Sensitive[String[1]] $sensitive_default_vmpooler_dev_token,
  Sensitive[String[1]] $sensitive_default_sles15_registration_code,
  Sensitive[String[1]] $sensitive_default_platform9_password,
  Array[String[1], 1] $default_solaris_hypervisor_snappaths = [ 'rpool/ROOT/zbe-0' ],
  String[1] $default_aix_hypervisor_keyfile                 = '/home/jenkins/.ssh/id_rsa-acceptance',
  String[1] $default_aix_hypervisor_server                  = 'rpm-builder.delivery.puppetlabs.net',
  String[1] $default_aix_hypervisor_username                = 'jenkins',
  String[1] $default_solaris_hypervisor_keyfile             = '/home/jenkins/.ssh/id_rsa-old.private',
  String[1] $default_solaris_hypervisor_server              = 'mundilfari.delivery.puppetlabs.net',
  String[1] $default_solaris_hypervisor_username            = 'harness',
  String[1] $default_solaris_hypervisor_vmpath              = 'rpool/zoneds',
  String[1] $default_vsphere_server                         = 'vcenter-ci1.ops.puppetlabs.net',
  String[1] $default_vsphere_username                       = 'eso-template@vsphere.local',
  String[1] $default_platform9_username                     = 'team-pr@puppet.com',
  String[1] $default_platform9_project                      = 'Team Puppet Romania',
  ) {
  # The imaging pipelines require the 'vcenter_instances' hash to be
  # present in the :default credentials group of the ~/.fog file.
  # However, BKR-1507 requires that each of these vcenter_instances be
  # represented as their own credentials group per the ~/.fog file
  # formatting conventions. To avoid duplicating config. values, we specify
  # our vcenter_instances in one place and just create the
  # vcenter_credentials_groups hash from it using some puppet code. Our ~/.fog
  # file is thus our :default credentials group + all of the
  # vcenter_credentials_groups.
  #
  # We should consider moving the vcenter_instances + vcenter_credentials
  # group code to a separate class to re-use it for IMAGES-882 once
  # that work begins.
  # New instance specific parameters are also specified on a per instance as
  # instead of being hard-coded into the logic of platform-ci-utils.
  # This will also simplify some of the parameters in the imaging ci-job-config
  # code in particular DEST_VCENTER_INSTANCES as the template directory is
  # properly bound to the instance definitions here.
  # The additional parameters are:
  # pool_file - vmpooler manifest file manifest file to be updated for any
  #             new or changed pools on this instance.
  # suffix    - Suffix to be applied to the pooler title (e.g. -pixa3)
  # build     - Build folder that will be used for the packer build.
  # templates - Folder where templates reside for this instance.
  # Not all instances have the variables (e.g prod1 only requires a
  # template location as pools are never deployed here)
  $vcenter_instances = {
    'vcenter-ci1'    => {
      'host'        => 'vcenter-ci1.ops.puppetlabs.net',
      'dc'          => 'opdx',
      'cluster'     => 'acceptance1',
      'provider'    => 'vsphere-ci65',
      'datastore'   => 'instance2_1',
      'network'     => 'vmpooler',
      'pool_file'   => 'site/profile/manifests/vmpooler/pools/cinext.pp',
      'suffix'      => '',
      'build'       => 'packer',
      'dest_folder' => 'templates',
      'base_folder' => '{{ default  .Values.vmpoolerInstance .Values.vmwareBaseFolder }}',
      'username'    => $default_vsphere_username,
      'password'    => unwrap($sensitive_default_vsphere_password),
    },
    'vcenter-ci1-mac2'    => {
      'host'      => 'vcenter-ci1.ops.puppetlabs.net',
      'dc'        => 'pix',
      'cluster'   => 'mac2',
      'datastore' => 'tintri-vmpooler-pix',
      'network'   => 'vmpooler',
      # TBD
      'username'  => $default_vsphere_username,
      'password'  => unwrap($sensitive_default_vsphere_password),
    },
    'vcenter-ci1-pix' => {
      'host'        => 'vcenter-ci1.ops.puppetlabs.net',
      'dc'          => 'pix',
      'provider'    => 'vsphere-ci65',
      'cluster'     => 'acceptance2',
      'datastore'   => 'vmpooler_netapp_prod_2',
      'network'     => 'vmpooler',
      'pool_file'   => 'site/profile/manifests/vmpooler/pools/cinext_pix.pp',
      'suffix'      => '',
      'dest_folder' => 'templates/netapp/acceptance2',
      'base_folder' => '{{ default  .Values.vmpoolerInstance .Values.vmwareBaseFolder }}',
      'username'    => $default_vsphere_username,
      'password'    => unwrap($sensitive_default_vsphere_password),
    },
    'vcenter-ci1-pixa4' => {
      'host'        => 'vcenter-ci1.ops.puppetlabs.net',
      'dc'          => 'pix',
      'provider'    => 'vsphere-ci65',
      'cluster'     => 'acceptance4',
      'datastore'   => 'vmpooler_netapp_prod',
      'network'     => 'vmpooler',
      'pool_file'   => 'site/profile/manifests/vmpooler/pools/cinext_pix_acceptance4.pp',
      'suffix'      => '-pixa4',
      'dest_folder' => 'templates/netapp/acceptance4',
      'base_folder' => '{{ default  .Values.vmpoolerInstance .Values.vmwareBaseFolder }}',
      'username'    => $default_vsphere_username,
      'password'    => unwrap($sensitive_default_vsphere_password),
    },
    'vcenter-prod1' => {
      'host'        => 'vcenter-prod1.ops.puppetlabs.net',
      'dc'          => 'opdx1',
      'provider'    => 'vsphere-ci65',
      'cluster'     => 'operations2',
      'datastore'   => 'tintri-opdx-1-general1',
      'network'     => 'ops',
      'build'       => 'packer',
      'dest_folder' => 'templates/ci',
      'base_folder' => '{{ default  .Values.vmpoolerInstance .Values.vmwareBaseFolder }}',
      'username'    => 'sre-template-creator@puppet.com',
      'password'    => unwrap($sensitive_default_static_vcenter_password),
    },
  }
  $vcenter_credentials_groups = $vcenter_instances.reduce({}) |$groups, $instance| {
    $config = $instance[1]
    $groups + {
      $config['host'] => {
        'vsphere_server'   => $config['host'],
        'vsphere_username' => $config['username'],
        'vsphere_password' => $config['password'],
      }
    }
  }

  # This is our top-level :default credentials group
  $default_credentials_group = {
    'default' => {
      'aix_hypervisor_keyfile'       => $default_aix_hypervisor_keyfile,
      'aix_hypervisor_server'        => $default_aix_hypervisor_server,
      'aix_hypervisor_username'      => $default_aix_hypervisor_username,
      'aws_access_key_id'            => unwrap($sensitive_default_aws_access_key_id),
      'aws_dev_access_key_id'        => unwrap($sensitive_default_aws_dev_access_key_id),
      'aws_dev_secret_access_key'    => unwrap($sensitive_default_aws_dev_secret_access_key),
      'aws_secret_access_key'        => unwrap($sensitive_default_aws_secret_access_key),
      'solaris_hypervisor_keyfile'   => $default_solaris_hypervisor_keyfile,
      'solaris_hypervisor_server'    => $default_solaris_hypervisor_server,
      'solaris_hypervisor_snappaths' => $default_solaris_hypervisor_snappaths,
      'solaris_hypervisor_username'  => $default_solaris_hypervisor_username,
      'solaris_hypervisor_vmpath'    => $default_solaris_hypervisor_vmpath,
      'vcenter_instances'            => $vcenter_instances,
      'vmpooler_instances'           => {
        'dev' => {
          'fqdn'  => 'vmpooler-dev.delivery.puppetlabs.net',
          'token' => unwrap($sensitive_default_vmpooler_dev_token),
        },
        'ci' => {
          'fqdn'  => 'vmpooler-cinext.delivery.puppetlabs.net',
          'token' => unwrap($sensitive_default_vmpooler_token),
        },
      },
      'platform9' => {
        'domain_id'   => 'default',
        'region'      => 'Portland',
        'domain'      => 'default',
        'project'     => $default_platform9_project,
        'api_version' => '3',
        'password'    => unwrap($sensitive_default_platform9_password),
        'nova_url'    => 'https://puppet.platform9.net/nova/v2.1',
        'auth_url'    => 'https://puppet.platform9.net/keystone/v3',
        'username'    => $default_platform9_username,
      },
      'vmpooler_token'               => unwrap($sensitive_default_vmpooler_token),
      'vsphere_password'             => unwrap($sensitive_default_vsphere_password),
      'vsphere_server'               => $default_vsphere_server,
      'vsphere_username'             => $default_vsphere_username,
      'sles15_registration_code'     => unwrap($sensitive_default_sles15_registration_code),
    },
  }

  # Every entry for the .fog file should be represented in this hash and have a
  # corresponding class paramater if overrides are applicable. All secrets should
  # be added to hiera and encrypted with eyaml. Default values are located in
  # hieradata/domains/delivery.puppetlabs.net.yaml
  $fog_hash = $default_credentials_group + $vcenter_credentials_groups
  $agent_home = $profile::jenkins::params::agent_home

  file { "${agent_home}/.fog":
    ensure  => file,
    mode    => '0640',
    owner   => $profile::jenkins::params::jenkins_owner,
    group   => $profile::jenkins::params::jenkins_group,
    content => to_symbolized_yaml($fog_hash).node_encrypt::secret,
    require => Account::User[$profile::jenkins::params::jenkins_owner],
  }
}
