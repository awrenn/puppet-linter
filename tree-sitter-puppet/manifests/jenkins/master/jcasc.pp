# profile for Jenkins Configuration as Code plugin file resources
class profile::jenkins::master::jcasc (
  Array[Enum['mesos', 'k8s', 'core', 'ldap', 'saml']] $jcasc_files_to_load = ['mesos', 'k8s', 'core', 'ldap'],
  String[1] $jcasc_dir                                    = 'jcasc',
  Integer $jnlp_port                                      = 5006, # static port needed since this is allowed in GKE firewall
  String[1] $k8s_jenkins_setup_namespace                  = 'ci-jenkins-setup',
  Integer $k8s_retention_timeout                          = 20,
  String[1] $k8s_server_url                               = 'https://gke-ci-test.causeway.it.puppet.net',
) {
  $master_jcasc_dir = "${profile::jenkins::params::master_config_dir}/${jcasc_dir}"

  file { $master_jcasc_dir:
    ensure => directory,
  }

  tidy { "tidy ${master_jcasc_dir}":
    path    => $master_jcasc_dir,
    recurse => true,
  }

  if 'mesos' in $jcasc_files_to_load {
    file { "${master_jcasc_dir}/jenkins-clouds-mesos.yaml":
      ensure  => file,
      content => file("profile/jenkins/master/mesos-cloud-${facts['networking']['hostname']}.yaml"),
    }
  }

  if 'k8s' in $jcasc_files_to_load {
    # kubenetes images global configurable variables. They can be overwritten on a per image basis below
    $k8_images_global = {
      'templateName'          => 'jnlp',
      'imagePullSecrets'      => 'artifactorydockercreds',
      'isWindowsImage'        => false,
      'namespace'             => $k8s_jenkins_setup_namespace,
      'resourceLimitCpu'      => '3',
      'resourceLimitMemory'   => '4G',
      'resourceRequestCpu'    => '2',
      'resourceRequestMemory' => '4G',
      'serviceAccount'        => 'jenkins',
      'agentRunAsUser'        => '22002',
      'agentRunAsGroup'       => '624',
    }

    # add custom images here, with a unique label name, which you have to refer to in your freestyle / matrix job
    # the name / image / labels combination will be processed as a kubernetes pod template
    # for pipelines, use the https://github.com/jenkinsci/kubernetes-plugin container support to load the custom
    # image as a sidecar
    $k8s_images_labels = [
      {
        'templateName'=> 'jnlp-parent',
        'name'        => 'jnlp',                             #this overwrites the default container to be the universal one
        'image'       => 'gcr.io/infracore/k8suniversal:12', # includes the jnlp agent binaries
        'entrypoint'  => '',
        'arguments'   => '',
        'labels'      => 'k8s-worker k8s-beaker c2m4',
      },
      {
        'name'                => 'jnlp',
        'image'               => 'gcr.io/infracore/k8suniversal:12',
        'entrypoint'          => '',
        'arguments'           => '',
        'labels'              => 'k8s-unit c2m6',
        'resourceLimitMemory' => '6G',
      },
      {
        'name'                  => 'jnlp',
        'image'                 => 'gcr.io/infracore/k8suniversal:12',
        'entrypoint'            => '',
        'arguments'             => '',
        'labels'                => 'c2m8',
        'resourceLimitCpu'      => '3',
        'resourceLimitMemory'   => '8G',
        'resourceRequestCpu'    => '2',
        'resourceRequestMemory' => '8G',
      },
      {
        'name'                  => 'jnlp',
        'image'                 => 'gcr.io/infracore/k8suniversal:12',
        'entrypoint'            => '',
        'arguments'             => '',
        'labels'                => 'c4m4',
        'resourceLimitCpu'      => '6',
        'resourceLimitMemory'   => '4G',
        'resourceRequestCpu'    => '4',
        'resourceRequestMemory' => '4G',
      },
      {
        'name'                  => 'jnlp',
        'image'                 => 'gcr.io/infracore/k8suniversal:12',
        'entrypoint'            => '',
        'arguments'             => '',
        'labels'                => 'c4m6',
        'resourceLimitCpu'      => '6',
        'resourceLimitMemory'   => '6G',
        'resourceRequestCpu'    => '4',
        'resourceRequestMemory' => '6G',
      },
      {
        'name'                  => 'jnlp',
        'image'                 => 'gcr.io/infracore/k8suniversal:12',
        'entrypoint'            => '',
        'arguments'             => '',
        'labels'                => 'c4m8',
        'resourceLimitCpu'      => '6',
        'resourceLimitMemory'   => '8G',
        'resourceRequestCpu'    => '4',
        'resourceRequestMemory' => '8G',
      },
      {
        'name'                => 'jnlp',
        'image'               => 'artifactory.delivery.puppetlabs.net/qe/k8s-cjc-manager:1',
        'entrypoint'          => '',
        'arguments'           => '',
        'labels'              => 'k8s-cjc-manager',
        'resourceLimitMemory' => '2G',
      },
      {
        'name'                  => 'jnlp',
        'image'                 => 'gcr.io/infracore/windows-1909-jenkins:1',
        'isWindowsImage'        => true,
        'entrypoint'            => '',
        'arguments'             => '',
        'labels'                => 'k8s-worker-windows',
        'resourceLimitCpu'      => '1',
        'resourceLimitMemory'   => '2G',
        'resourceRequestCpu'    => '1',
        'resourceRequestMemory' => '2G',
        'workingDir'            => 'C:/Users/jenkins/Work',
      },
      {
        'templateName'=> 'jnlp-parent-git', #to be used as a template to inherit from when only git is needed (less resources assigned), but still loads secrets
        'name'        => 'jnlp',
        'image'       => 'gcr.io/infracore/k8sjnlpgit:1', #from docker-ci-tools repo /dockerfiles/debian/buster/jenkins-agent
        'entrypoint'  => '',
        'arguments'   => '',
        'labels'      => 'k8s-jnlp-git',
        'resourceLimitCpu'      => '',
        'resourceLimitMemory'   => '',
        'resourceRequestCpu'    => '100m',
        'resourceRequestMemory' => '256Mi',
        'agentRunAsUser'        => '1000',
        'agentRunAsGroup'       => '1000',
      },
      # ADD custom images here
      #{
      #  'name'        => 'containername', # unique name, refer to this name in pipelines
      #  'image'       => 'artifactory.delivery.puppetlabs.net/repo/image:tag', # the custom image
      #  'entrypoint'  => 'jenkins-slave', # empty string or overwrite the default entrypoint
      #  'arguments'   => '', # empty string or arguments to pass to the entrypoint command above
      #  'labels'      => 'worker beaker', # unique names that can be used to reference this custom image in freestyle / matrix jobs labels
      #},
    ]

    $k8s_templates = $k8s_images_labels.map |$k8s_images_label| {
      $data = $k8_images_global + $k8s_images_label
      if $data['isWindowsImage'] {
        $_annotations = [
          {
            'key'   => 'vault.hashicorp.com/agent-inject',
            'value' => 'false',
          },
        ]
      } else {
        $_annotations = [
          {
            'key'   => 'vault.hashicorp.com/agent-inject',
            'value' => 'true',
          },
          {
            'key'   => 'vault.hashicorp.com/agent-configmap',
            'value' => 'configmap-jenkins-vault-injector',
          },
          {
            'key'   => 'vault.hashicorp.com/agent-pre-populate-only',
            'value' => 'true',
          },
          {
            'key'   => 'vault.hashicorp.com/agent-run-as-user',
            'value' => $data['agentRunAsUser'],
          },
          {
            'key'   => 'vault.hashicorp.com/agent-run-as-group',
            'value' => $data['agentRunAsGroup'],
          },
        ]
      }

      $_container_base_args = '' # container template arguments for all of them

      $_container_args = $data['arguments'] ? {
        ''      => $_container_base_args,
        default => "${_container_base_args} ${data['arguments']}",
      }

      $_privileged = $data['isWindowsImage'] ? {
        true    => false,
        default => true,
      }

      $_slave_connect_timeout = $data['isWindowsImage'] ? {
        true    => 1200,
        default => 600,
      }

      $_containers = [delete_undef_values({
        'image'                 => $data['image'],
        'args'                  => $_container_args,
        'command'               => $data['entrypoint'],
        'name'                  => $data['name'],
        'privileged'            => $_privileged,
        'alwaysPullImage'       => true,
        'resourceLimitCpu'      => $data['resourceLimitCpu'],
        'resourceLimitMemory'   => $data['resourceLimitMemory'],
        'resourceRequestCpu'    => $data['resourceRequestCpu'],
        'resourceRequestMemory' => $data['resourceRequestMemory'],
        'ttyEnabled'            => true,
        'workingDir'            => $data['workingDir'],
      })]

      $_image_pull_secrets = [{
        'name' => $data['imagePullSecrets'],
      }]

      $_yaml_spec_toleration_section = $data['isWindowsImage'] ? {
        true => {
          'tolerations' => [{
            'key'      => 'node.kubernetes.io/os',
            'operator' => 'Equal',
            'value'    => 'windows',
            'effect'   => 'NoSchedule',
          }],
        },
        default => {},
      }

      $_yaml_spec_containers_section = $data['isWindowsImage'] ? {
        false => {
          'containers'  => [{
            'name'           => 'jnlp',
            'readinessProbe' => {
              'exec' => {
                'command' => [
                  'ls',
                  '/vault/secrets',
                ],
                'failureThreshold' => 1,
              },
            },
          }],
        },
        default => {},
      }

      $_yaml_spec_nodeselector_windows_section = $data['isWindowsImage'] ? {
        true    => true,
        default => undef,
      }

      $_yaml_spec_nodeselector_section = {
        'nodeSelector' => delete_undef_values({
          'spotinst.io/node-lifecycle' => 'od',
          'runOnWin' => $_yaml_spec_nodeselector_windows_section,
        }),
      }

      $yaml_string = to_yaml({
        'apiVersion' => 'v1',
        'kind'       => 'Pod',
        'metadata'   => {
          'labels' => {
            'spotinst.io/restrict-scale-down' => 'true',
          },
        },
        'spec' => delete_undef_values($_yaml_spec_nodeselector_section + $_yaml_spec_containers_section + $_yaml_spec_toleration_section),
      })

      # final hash returned for each label
      delete_undef_values({
        'annotations'         => $_annotations,
        'containers'          => $_containers,
        'imagePullSecrets'    => $_image_pull_secrets,
        'label'               => $data['labels'],
        'name'                => $data['templateName'],
        'namespace'           => $data['namespace'],
        'podRetention'        => $data['podRetention'],
        'serviceAccount'      => $data['serviceAccount'],
        'slaveConnectTimeout' => $_slave_connect_timeout,
        'yamlMergeStrategy'   => 'merge',
        'yaml'                => $yaml_string,
        'workspaceVolume'     => {
          'emptyDirWorkspaceVolume' => {
            'memory' => false,
          },
        },
      })
    }

    $jenkins_clouds_k8s = {
      'jenkins' => {
        'clouds' => [
          'kubernetes' => {
            'containerCapStr'       => '500',                          # The maximum number of concurrently running agent pods that are permitted in this Kubernetes Cloud
            'credentialsId'         => 'infracore-ci-test-kubernetes', # the jenkins credentials to use as auth to the k8s cluster
            'jenkinsUrl'            => 'https://${MYHOSTNAME}',
            'name'                  => 'kubernetes',
            'namespace'             => $k8s_jenkins_setup_namespace,
            'retentionTimeout'      => $k8s_retention_timeout,         # Must increase timeout to avoid early termination of Windows agents becuase the nodes take longer to spin up
            'serverUrl'             => $k8s_server_url,                # kubernetes API server config
            'connectTimeout'        => 5,
            'readTimeout'           => 15,
            'maxRequestsPerHostStr' => '32',                           # The maximum number of concurrent requests to the Kubernetes API
            'skipTlsVerify'         => false,                          # Should be false in production, the reverse proxies have valid certs
            'templates'             => $k8s_templates,
            'webSocket'             => true,
          },
        ],
      },
    }

    file { "${master_jcasc_dir}/jenkins-clouds-k8s.yaml":
      owner   => $jenkins_owner,
      group   => $jenkins_group,
      mode    => '0755',
      content => to_yaml($jenkins_clouds_k8s),
    }
  }

  if 'core' in $jcasc_files_to_load {
    file { "${master_jcasc_dir}/jenkins-core.yaml":
      owner   => $jenkins_owner,
      group   => $jenkins_group,
      mode    => '0755',
      content => template('profile/jenkins/master/jenkins-core.yaml.erb'),
    }
  }

  if 'ldap' in $jcasc_files_to_load {
    $sensitive_ldap_manager_password = unwrap(lookup('profile::jenkins::master::sensitive_ldap_manager_password'))

    file { "${master_jcasc_dir}/jenkins-security-ldap.yaml":
      owner   => $jenkins_owner,
      group   => $jenkins_group,
      mode    => '0755',
      content => template('profile/jenkins/master/jenkins-security-ldap.yaml.erb'),
    }
  }

  if 'saml' in $jcasc_files_to_load {
    $sensitive_okta_idp_metadata = unwrap(lookup('profile::jenkins::master::sensitive_okta_idp_metadata'))
    $sensitive_okta_idp_metadata_url = unwrap(lookup('profile::jenkins::master::sensitive_okta_idp_metadata_url'))

    file { "${master_jcasc_dir}/jenkins-security-saml.yaml":
      owner   => $jenkins_owner,
      group   => $jenkins_group,
      mode    => '0755',
      content => template('profile/jenkins/master/jenkins-security-saml.yaml.erb'),
    }
  }
}
