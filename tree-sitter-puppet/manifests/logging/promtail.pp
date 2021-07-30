# Setup promtail to ship to Loki
class profile::logging::promtail (
  Hash $clients_config_hash,
  Hash $positions_config_hash,
  Hash $scrape_configs_hash,
  Sensitive[String[1]] $sensitive_password_file_content,
  Stdlib::Absolutepath $password_file_path,
  Boolean $deep_merge_scrape_configs = true,
  Enum['running', 'stopped'] $service_ensure = running,
  String[1] $checksum = 'd37e94e6ce0604f9faea7738f9c35d83afbdca9e5e92537600764a3b18cfe088',
  String[1] $version = 'v2.0.0',
  Optional[Hash] $server_config_hash = undef,
  Optional[Hash] $target_config_hash = undef,
  Optional[Stdlib::Absolutepath] $bin_dir = undef,
){
  if $deep_merge_scrape_configs {
    $_real_scrape_configs_hash = lookup('profile::logging::promtail::scrape_configs_hash', {merge => 'deep'})
  }
  else {
    $_real_scrape_configs_hash = $scrape_configs_hash
  }

  class { 'promtail':
    clients_config_hash   => $clients_config_hash,
    positions_config_hash => $positions_config_hash,
    scrape_configs_hash   => $_real_scrape_configs_hash,
    password_file_content => $sensitive_password_file_content,
    password_file_path    => $password_file_path,
    service_ensure        => $service_ensure,
    server_config_hash    => $server_config_hash,
    target_config_hash    => $target_config_hash,
    bin_dir               => $bin_dir,
    checksum              => $checksum,
    version               => $version,
  }
}

