class profile::server::windows {
  include pe_patch
  include profile::base
  include profile::pe::comply
  include profile::server
  if $profile::server::fw {
    include profile::fw::windows
  }

  if $profile::server::metrics {
      include profile::metrics
      Class['profile::base'] -> Class['profile::metrics']
    }
}
