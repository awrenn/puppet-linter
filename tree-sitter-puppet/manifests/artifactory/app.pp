class profile::artifactory::app (
  Boolean $is_primary,
  Sensitive[String[1]] $sensitive_artifact_cleaner_api_key,
  Stdlib::Httpsurl $jfrog_artifact_cleanup_plugin,
  Stdlib::Unixpath $plugin_directory,
  Stdlib::Unixpath $plugin_lib_directory,
  String[1] $artifactory_group,
  String[1] $artifactory_user,
  String[1] $application_package_name,
  String[3] $application_version,
  ) {
  profile_metadata::service { $title:
    human_name => 'Artifactory application',
    owner_uid  => 'eric.griswold',
    team       => re,
    end_users  => ['org-products@puppet.com'],
    doc_urls   => [
      'https://confluence.puppetlabs.com/display/RE/Artifactory+Basics',
    ],
  }

  Account::User <| title == $artifactory_user |>

  $artifact_cleanup_script_url = 'puppet:///modules/profile/artifactory/artifact-cleanup'

  $clean_docker_images_script_url = 'puppet:///modules/profile/artifactory/clean-docker-images'
  $clean_docker_images_properties_url = 'puppet:///modules/profile/artifactory/cleanDockerImages.properties'

  $delete_empty_directories_script_url = 'puppet:///modules/profile/artifactory/delete-empty-directories'
  $delete_empty_directories_properties_url = 'puppet:///modules/profile/artifactory/deleteEmptyDirs.properties'

  # These are tweaks to files, mostly systemd related, needed to handle centos >7.5
  file { '/usr/lib/systemd/system/artifactory.service':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0640',
    source => 'puppet:///modules/profile/artifactory/systemd_related_patches/artifactory.service',
  }

  file_line { 'Set Artifactory JAVA_HOME':
    path => '/etc/opt/jfrog/artifactory/default',
    line => 'export JAVA_HOME=/usr',
  }

  file { '/opt/jfrog/artifactory/bin/artifactoryManage.sh':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0775',
    source => 'puppet:///modules/profile/artifactory/systemd_related_patches/artifactoryManage.sh',
  }
  # End of centos >7.5 tweaks


  class { 'java':
    package => 'java-1.8.0-openjdk-devel',
  }

  yumrepo { 'bintray-jfrog-artifactory-pro-rpms':
    baseurl  => 'http://jfrog.bintray.com/artifactory-pro-rpms',
    descr    => 'Artifactory YUM repository',
    gpgcheck => 0,
    enabled  => 1,
  }

  package { "${application_package_name}":
    ensure  => $application_version,
    require => Yumrepo['bintray-jfrog-artifactory-pro-rpms'],
  }

  ulimit::rule {'artifactory file limits':
    ulimit_domain => 'artifactory',
    ulimit_type   => '-',
    ulimit_item   => 'nofile',
    ulimit_value  => '32000',
  }

  # NFS mount for artifactory app machines
  mount { '/srv/artifactory1':
    ensure  => 'mounted',
    device  => 'artifactory-nfs-prod-1.delivery.puppetlabs.net:/srv/artifactory1',
    fstype  => 'nfs',
    options => 'rw,async,hard,intr',
  }

  if ($is_primary) {
    # JFrog artifactCleanup plugin
    $artifact_cleanup_install_path = "${plugin_directory}/artifactCleanup.groovy"
    archive { $artifact_cleanup_install_path:
      ensure => present,
      source => $jfrog_artifact_cleanup_plugin,
      user   => $artifactory_user,
      group  => $artifactory_group,
    }
    exec { 'artifactCleanup permission':
      command   => "/bin/chmod 644 ${artifact_cleanup_install_path}",
      subscribe => Archive[$artifact_cleanup_install_path],
    }

    # JFrog deleteEmptyDirs plugin
    $delete_empty_dirs_install_path = "${plugin_directory}/deleteEmptyDirs.groovy"
    archive { $delete_empty_dirs_install_path:
      ensure => present,
      source => $jfrog_delete_empty_dirs_plugin,
      user   => $artifactory_user,
      group  => $artifactory_group,
    }
    exec { 'deleteEmptyDirs permission':
      command   => "/bin/chmod 644 ${delete_empty_dirs_install_path}",
      subscribe => Archive[$delete_empty_dirs_install_path],
    }

    file {
      default:
        ensure => 'file',
        owner  => $artifactory_user,
        group  => $artifactory_group,
      ;
      'plugin lib directory':
        ensure => 'directory',
        path   => "${plugin_lib_directory}",
        mode   => '0750',
      ;
      'artifact cleanup script':
        path    => "${plugin_lib_directory}/artifact-cleanup",
        source  => $artifact_cleanup_script_url,
        mode    => '0750',
        require => File["${plugin_lib_directory}"],
      ;
      'delete empty directories script':
        path    => "${plugin_lib_directory}/delete-empty-directories",
        source  => $delete_empty_directories_script_url,
        mode    => '0750',
        require => File["${plugin_lib_directory}"],
      ;
      'delete empty directories properties':
        path   => "${plugin_directory}/deleteEmptyDirs.properties",
        source => $delete_empty_directories_properties_url,
        mode   => '0644',
      ;
      'clean docker images plugin':
        path   => "${plugin_directory}/cleanDockerImages.groovy",
        source => $jfrog_clean_docker_images_plugin,
        mode   => '0644',
      ;
      'clean docker images script':
        path    => "${plugin_lib_directory}/clean-docker-images",
        source  => $clean_docker_images_script_url,
        mode    => '0750',
        require => File["${plugin_lib_directory}"],
      ;
      'clean docker images properties':
        path   => "${plugin_directory}/cleanDockerImages.properties",
        source => $clean_docker_images_properties_url,
        mode   => '0644',
      ;
      'cleanup api key file':
        path    => "${plugin_lib_directory}/cleanup_api_key",
        mode    => '0600',
        content => $sensitive_artifact_cleaner_api_key.node_encrypt::secret,
      ;
    }

    cron { 'artifact_cleanup':
      user    => $artifactory_user,
      command => "${plugin_lib_directory}/artifact-cleanup ${plugin_lib_directory}/cleanup_api_key > /var/opt/jfrog/artifactory/logs/artifact-cleanup.log 2>&1",
      hour    => 6,
      minute  => 0,
      require => File["${plugin_lib_directory}/artifact-cleanup"],
    }

    cron { 'clean_docker_images':
      user    => $artifactory_user,
      command => "${plugin_lib_directory}/clean-docker-images ${plugin_lib_directory}/cleanup_api_key > /var/opt/jfrog/artifactory/logs/clean-docker-images.log 2>&1",
      hour    => 4,
      minute  => 0,
      require => File["${plugin_lib_directory}/clean-docker-images"],
    }

    cron { 'delete empty directories':
      user    => $artifactory_user,
      command => "${plugin_lib_directory}/delete-empty-directories ${plugin_lib_directory}/cleanup_api_key > /var/opt/jfrog/artifactory/logs/delete-empty-directories.log 2>&1",
      weekday => 'Monday',
      hour    => 8,
      minute  => 0,
      require => File["${plugin_lib_directory}/delete-empty-directories"],
    }
  }
}
