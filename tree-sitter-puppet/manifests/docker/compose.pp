class profile::docker::compose (
  String[1] $compose_version,
) {

  class {'docker::compose':
    ensure  => present,
    version => $compose_version,
  }

  # Private registries need to be setup before you can pull images from them...
  Docker::Registry <| |> -> Docker_compose <| |>
  Docker::Registry <| |> -> Docker::Image <| |>

  $registries = lookup( 'docker::registry_auth::registries', { 'value_type' => Variant[Hash, Undef], 'default_value' => undef } )
  if $registries {
    include docker::registry_auth
  }

  $images = lookup( 'docker::images::images', { 'value_type' => Variant[Hash, Undef], 'default_value' => undef } )
  if $images {
    include docker::images
  }

  $instances = lookup( 'docker::run_instance::instance', { 'value_type' => Variant[Hash, Undef], 'default_value' => undef })
  if $instances {
    include docker::run_instance
  }

  $composed_instances = lookup( 'docker::composed_instances', { 'value_type' => Variant[Array, Undef], 'default_value' => undef })
  if $composed_instances {
    $compose_file_dir = '/docker-compose-files'
    file { $compose_file_dir:
      ensure  => directory,
      owner   => 'root',
      group   => 'docker',
      mode    => '0770',
      require => Group['docker'],
    }

    $composed_instances.each |$composed_instance| {
      $dirname = $composed_instance.regsubst(/\.yml$/, '')
      $compose_file = "${compose_file_dir}/${dirname}/docker-compose.yml"
      file { "${compose_file_dir}/${dirname}":
        ensure  => directory,
        owner   => 'root',
        group   => 'docker',
        mode    => '0770',
        require => Group['docker'],
      }

      file { $compose_file:
        ensure => file,
        owner  => 'root',
        group  => 'docker',
        mode   => '0550',
        source => "puppet:///modules/profile/docker/${composed_instance}",
      }

      docker_compose { $compose_file:
        ensure        => present,
        compose_files => [$compose_file],
        require       => File[$compose_file],
      }
    }
  }

  $services = lookup( 'docker::services::services', { 'value_type' => Variant[Hash, Undef], 'default_value' => undef })
  if $services {
    create_resources(docker::services, $services)
  }

  $stacks = lookup( 'docker::stacks', { 'value_type' => Variant[Array[Hash], Undef], 'default_value' => undef })
  $eyamled_stacks = lookup( 'docker::eyamled_stacks', { 'value_type' => Variant[Array[Hash], Undef], 'default_value' => undef })
  if $stacks or $eyamled_stacks {
    $stack_file_dir = '/docker-stack-files'
    file { $stack_file_dir:
      ensure  => directory,
      owner   => 'root',
      group   => 'docker',
      mode    => '0770',
      require => Group['docker'],
    }

    if $stacks {
      $stacks.each |$stack| {
        $stack.each |$stack_name, $compose_file| {
          $dirname = $compose_file.regsubst(/\.yml$/, '')
          $stack_file = "${stack_file_dir}/${dirname}/docker-compose.yml"
          file { "${stack_file_dir}/${dirname}":
            ensure  => directory,
            owner   => 'root',
            group   => 'docker',
            mode    => '0770',
            require => Group['docker'],
          }

          file { $stack_file:
            ensure => file,
            owner  => 'root',
            group  => 'docker',
            mode   => '0550',
            source => "puppet:///modules/profile/docker/${compose_file}",
          }

          docker::stack { $stack_name:
            ensure        => present,
            stack_name    => $stack_name,
            compose_files => [ $stack_file, ],
            require       => File[$stack_file],
          }
        }
      } # end stacks.each
    } # end if $stacks

    if $eyamled_stacks {
      $eyamled_stacks.each |$eyamled_stack| {
        $dirname = $eyamled_stack[compose_file].regsubst(/\.yml$/, '')
        $stack_file = "${stack_file_dir}/${dirname}/docker-compose.yml"
        file { "${stack_file_dir}/${dirname}":
          ensure  => directory,
          owner   => 'root',
          group   => 'docker',
          mode    => '0770',
          require => Group['docker'],
        }

        file { $stack_file:
          ensure  => file,
          owner   => 'root',
          group   => 'docker',
          mode    => '0550',
          content => epp("profile/docker/${eyamled_stack[compose_file]}.epp", { 'secrets' => $eyamled_stack[secrets] }),
        }

          docker::stack { $eyamled_stack[stack_name]:
            ensure        => present,
            stack_name    => $eyamled_stack[stack_name],
            compose_files => [ $stack_file, ],
            require       => File[$stack_file],
          }

      } # end eyamled_stacks.each
    } # end if $eyamled_stacks
  }
}
